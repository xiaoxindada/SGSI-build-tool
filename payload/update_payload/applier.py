#
# Copyright (C) 2013 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

"""Applying a Chrome OS update payload.

This module is used internally by the main Payload class for applying an update
payload. The interface for invoking the applier is as follows:

  applier = PayloadApplier(payload)
  applier.Run(...)

"""

from __future__ import print_function

import array
import bz2
import hashlib
import itertools
# Not everywhere we can have the lzma library so we ignore it if we didn't have
# it because it is not going to be used. For example, 'cros flash' uses
# devserver code which eventually loads this file, but the lzma library is not
# included in the client test devices, and it is not necessary to do so. But
# lzma is not used in 'cros flash' so it should be fine. Python 3.x include
# lzma, but for backward compatibility with Python 2.7, backports-lzma is
# needed.
try:
  import lzma
except ImportError:
  try:
    from backports import lzma
  except ImportError:
    pass
import os
import shutil
import subprocess
import sys
import tempfile

from update_payload import common
from update_payload.error import PayloadError


#
# Helper functions.
#
def _VerifySha256(file_obj, expected_hash, name, length=-1):
  """Verifies the SHA256 hash of a file.

  Args:
    file_obj: file object to read
    expected_hash: the hash digest we expect to be getting
    name: name string of this hash, for error reporting
    length: precise length of data to verify (optional)

  Raises:
    PayloadError if computed hash doesn't match expected one, or if fails to
    read the specified length of data.
  """
  hasher = hashlib.sha256()
  block_length = 1024 * 1024
  max_length = length if length >= 0 else sys.maxint

  while max_length > 0:
    read_length = min(max_length, block_length)
    data = file_obj.read(read_length)
    if not data:
      break
    max_length -= len(data)
    hasher.update(data)

  if length >= 0 and max_length > 0:
    raise PayloadError(
        'insufficient data (%d instead of %d) when verifying %s' %
        (length - max_length, length, name))

  actual_hash = hasher.digest()
  if actual_hash != expected_hash:
    raise PayloadError('%s hash (%s) not as expected (%s)' %
                       (name, common.FormatSha256(actual_hash),
                        common.FormatSha256(expected_hash)))


def _ReadExtents(file_obj, extents, block_size, max_length=-1):
  """Reads data from file as defined by extent sequence.

  This tries to be efficient by not copying data as it is read in chunks.

  Args:
    file_obj: file object
    extents: sequence of block extents (offset and length)
    block_size: size of each block
    max_length: maximum length to read (optional)

  Returns:
    A character array containing the concatenated read data.
  """
  data = array.array('c')
  if max_length < 0:
    max_length = sys.maxint
  for ex in extents:
    if max_length == 0:
      break
    read_length = min(max_length, ex.num_blocks * block_size)

    # Fill with zeros or read from file, depending on the type of extent.
    if ex.start_block == common.PSEUDO_EXTENT_MARKER:
      data.extend(itertools.repeat('\0', read_length))
    else:
      file_obj.seek(ex.start_block * block_size)
      data.fromfile(file_obj, read_length)

    max_length -= read_length

  return data


def _WriteExtents(file_obj, data, extents, block_size, base_name):
  """Writes data to file as defined by extent sequence.

  This tries to be efficient by not copy data as it is written in chunks.

  Args:
    file_obj: file object
    data: data to write
    extents: sequence of block extents (offset and length)
    block_size: size of each block
    base_name: name string of extent sequence for error reporting

  Raises:
    PayloadError when things don't add up.
  """
  data_offset = 0
  data_length = len(data)
  for ex, ex_name in common.ExtentIter(extents, base_name):
    if not data_length:
      raise PayloadError('%s: more write extents than data' % ex_name)
    write_length = min(data_length, ex.num_blocks * block_size)

    # Only do actual writing if this is not a pseudo-extent.
    if ex.start_block != common.PSEUDO_EXTENT_MARKER:
      file_obj.seek(ex.start_block * block_size)
      data_view = buffer(data, data_offset, write_length)
      file_obj.write(data_view)

    data_offset += write_length
    data_length -= write_length

  if data_length:
    raise PayloadError('%s: more data than write extents' % base_name)


def _ExtentsToBspatchArg(extents, block_size, base_name, data_length=-1):
  """Translates an extent sequence into a bspatch-compatible string argument.

  Args:
    extents: sequence of block extents (offset and length)
    block_size: size of each block
    base_name: name string of extent sequence for error reporting
    data_length: the actual total length of the data in bytes (optional)

  Returns:
    A tuple consisting of (i) a string of the form
    "off_1:len_1,...,off_n:len_n", (ii) an offset where zero padding is needed
    for filling the last extent, (iii) the length of the padding (zero means no
    padding is needed and the extents cover the full length of data).

  Raises:
    PayloadError if data_length is too short or too long.
  """
  arg = ''
  pad_off = pad_len = 0
  if data_length < 0:
    data_length = sys.maxint
  for ex, ex_name in common.ExtentIter(extents, base_name):
    if not data_length:
      raise PayloadError('%s: more extents than total data length' % ex_name)

    is_pseudo = ex.start_block == common.PSEUDO_EXTENT_MARKER
    start_byte = -1 if is_pseudo else ex.start_block * block_size
    num_bytes = ex.num_blocks * block_size
    if data_length < num_bytes:
      # We're only padding a real extent.
      if not is_pseudo:
        pad_off = start_byte + data_length
        pad_len = num_bytes - data_length

      num_bytes = data_length

    arg += '%s%d:%d' % (arg and ',', start_byte, num_bytes)
    data_length -= num_bytes

  if data_length:
    raise PayloadError('%s: extents not covering full data length' % base_name)

  return arg, pad_off, pad_len


#
# Payload application.
#
class PayloadApplier(object):
  """Applying an update payload.

  This is a short-lived object whose purpose is to isolate the logic used for
  applying an update payload.
  """

  def __init__(self, payload, bsdiff_in_place=True, bspatch_path=None,
               puffpatch_path=None, truncate_to_expected_size=True):
    """Initialize the applier.

    Args:
      payload: the payload object to check
      bsdiff_in_place: whether to perform BSDIFF operation in-place (optional)
      bspatch_path: path to the bspatch binary (optional)
      puffpatch_path: path to the puffpatch binary (optional)
      truncate_to_expected_size: whether to truncate the resulting partitions
                                 to their expected sizes, as specified in the
                                 payload (optional)
    """
    assert payload.is_init, 'uninitialized update payload'
    self.payload = payload
    self.block_size = payload.manifest.block_size
    self.minor_version = payload.manifest.minor_version
    self.bsdiff_in_place = bsdiff_in_place
    self.bspatch_path = bspatch_path or 'bspatch'
    self.puffpatch_path = puffpatch_path or 'puffin'
    self.truncate_to_expected_size = truncate_to_expected_size

  def _ApplyReplaceOperation(self, op, op_name, out_data, part_file, part_size):
    """Applies a REPLACE{,_BZ,_XZ} operation.

    Args:
      op: the operation object
      op_name: name string for error reporting
      out_data: the data to be written
      part_file: the partition file object
      part_size: the size of the partition

    Raises:
      PayloadError if something goes wrong.
    """
    block_size = self.block_size
    data_length = len(out_data)

    # Decompress data if needed.
    if op.type == common.OpType.REPLACE_BZ:
      out_data = bz2.decompress(out_data)
      data_length = len(out_data)
    elif op.type == common.OpType.REPLACE_XZ:
      # pylint: disable=no-member
      out_data = lzma.decompress(out_data)
      data_length = len(out_data)

    # Write data to blocks specified in dst extents.
    data_start = 0
    for ex, ex_name in common.ExtentIter(op.dst_extents,
                                         '%s.dst_extents' % op_name):
      start_block = ex.start_block
      num_blocks = ex.num_blocks
      count = num_blocks * block_size

      # Make sure it's not a fake (signature) operation.
      if start_block != common.PSEUDO_EXTENT_MARKER:
        data_end = data_start + count

        # Make sure we're not running past partition boundary.
        if (start_block + num_blocks) * block_size > part_size:
          raise PayloadError(
              '%s: extent (%s) exceeds partition size (%d)' %
              (ex_name, common.FormatExtent(ex, block_size),
               part_size))

        # Make sure that we have enough data to write.
        if data_end >= data_length + block_size:
          raise PayloadError(
              '%s: more dst blocks than data (even with padding)')

        # Pad with zeros if necessary.
        if data_end > data_length:
          padding = data_end - data_length
          out_data += '\0' * padding

        self.payload.payload_file.seek(start_block * block_size)
        part_file.seek(start_block * block_size)
        part_file.write(out_data[data_start:data_end])

      data_start += count

    # Make sure we wrote all data.
    if data_start < data_length:
      raise PayloadError('%s: wrote fewer bytes (%d) than expected (%d)' %
                         (op_name, data_start, data_length))

  def _ApplyMoveOperation(self, op, op_name, part_file):
    """Applies a MOVE operation.

    Note that this operation must read the whole block data from the input and
    only then dump it, due to our in-place update semantics; otherwise, it
    might clobber data midway through.

    Args:
      op: the operation object
      op_name: name string for error reporting
      part_file: the partition file object

    Raises:
      PayloadError if something goes wrong.
    """
    block_size = self.block_size

    # Gather input raw data from src extents.
    in_data = _ReadExtents(part_file, op.src_extents, block_size)

    # Dump extracted data to dst extents.
    _WriteExtents(part_file, in_data, op.dst_extents, block_size,
                  '%s.dst_extents' % op_name)

  def _ApplyZeroOperation(self, op, op_name, part_file):
    """Applies a ZERO operation.

    Args:
      op: the operation object
      op_name: name string for error reporting
      part_file: the partition file object

    Raises:
      PayloadError if something goes wrong.
    """
    block_size = self.block_size
    base_name = '%s.dst_extents' % op_name

    # Iterate over the extents and write zero.
    # pylint: disable=unused-variable
    for ex, ex_name in common.ExtentIter(op.dst_extents, base_name):
      # Only do actual writing if this is not a pseudo-extent.
      if ex.start_block != common.PSEUDO_EXTENT_MARKER:
        part_file.seek(ex.start_block * block_size)
        part_file.write('\0' * (ex.num_blocks * block_size))

  def _ApplySourceCopyOperation(self, op, op_name, old_part_file,
                                new_part_file):
    """Applies a SOURCE_COPY operation.

    Args:
      op: the operation object
      op_name: name string for error reporting
      old_part_file: the old partition file object
      new_part_file: the new partition file object

    Raises:
      PayloadError if something goes wrong.
    """
    if not old_part_file:
      raise PayloadError(
          '%s: no source partition file provided for operation type (%d)' %
          (op_name, op.type))

    block_size = self.block_size

    # Gather input raw data from src extents.
    in_data = _ReadExtents(old_part_file, op.src_extents, block_size)

    # Dump extracted data to dst extents.
    _WriteExtents(new_part_file, in_data, op.dst_extents, block_size,
                  '%s.dst_extents' % op_name)

  def _BytesInExtents(self, extents, base_name):
    """Counts the length of extents in bytes.

    Args:
      extents: The list of Extents.
      base_name: For error reporting.

    Returns:
      The number of bytes in extents.
    """

    length = 0
    # pylint: disable=unused-variable
    for ex, ex_name in common.ExtentIter(extents, base_name):
      length += ex.num_blocks * self.block_size
    return length

  def _ApplyDiffOperation(self, op, op_name, patch_data, old_part_file,
                          new_part_file):
    """Applies a SOURCE_BSDIFF, BROTLI_BSDIFF or PUFFDIFF operation.

    Args:
      op: the operation object
      op_name: name string for error reporting
      patch_data: the binary patch content
      old_part_file: the source partition file object
      new_part_file: the target partition file object

    Raises:
      PayloadError if something goes wrong.
    """
    if not old_part_file:
      raise PayloadError(
          '%s: no source partition file provided for operation type (%d)' %
          (op_name, op.type))

    block_size = self.block_size

    # Dump patch data to file.
    with tempfile.NamedTemporaryFile(delete=False) as patch_file:
      patch_file_name = patch_file.name
      patch_file.write(patch_data)

    if (hasattr(new_part_file, 'fileno') and
        ((not old_part_file) or hasattr(old_part_file, 'fileno'))):
      # Construct input and output extents argument for bspatch.

      in_extents_arg, _, _ = _ExtentsToBspatchArg(
          op.src_extents, block_size, '%s.src_extents' % op_name,
          data_length=op.src_length if op.src_length else
          self._BytesInExtents(op.src_extents, "%s.src_extents"))
      out_extents_arg, pad_off, pad_len = _ExtentsToBspatchArg(
          op.dst_extents, block_size, '%s.dst_extents' % op_name,
          data_length=op.dst_length if op.dst_length else
          self._BytesInExtents(op.dst_extents, "%s.dst_extents"))

      new_file_name = '/dev/fd/%d' % new_part_file.fileno()
      # Diff from source partition.
      old_file_name = '/dev/fd/%d' % old_part_file.fileno()

      if op.type in (common.OpType.BSDIFF, common.OpType.SOURCE_BSDIFF,
                     common.OpType.BROTLI_BSDIFF):
        # Invoke bspatch on partition file with extents args.
        bspatch_cmd = [self.bspatch_path, old_file_name, new_file_name,
                       patch_file_name, in_extents_arg, out_extents_arg]
        subprocess.check_call(bspatch_cmd)
      elif op.type == common.OpType.PUFFDIFF:
        # Invoke puffpatch on partition file with extents args.
        puffpatch_cmd = [self.puffpatch_path,
                         "--operation=puffpatch",
                         "--src_file=%s" % old_file_name,
                         "--dst_file=%s" % new_file_name,
                         "--patch_file=%s" % patch_file_name,
                         "--src_extents=%s" % in_extents_arg,
                         "--dst_extents=%s" % out_extents_arg]
        subprocess.check_call(puffpatch_cmd)
      else:
        raise PayloadError("Unknown operation %s", op.type)

      # Pad with zeros past the total output length.
      if pad_len:
        new_part_file.seek(pad_off)
        new_part_file.write('\0' * pad_len)
    else:
      # Gather input raw data and write to a temp file.
      input_part_file = old_part_file if old_part_file else new_part_file
      in_data = _ReadExtents(input_part_file, op.src_extents, block_size,
                             max_length=op.src_length if op.src_length else
                             self._BytesInExtents(op.src_extents,
                                                  "%s.src_extents"))
      with tempfile.NamedTemporaryFile(delete=False) as in_file:
        in_file_name = in_file.name
        in_file.write(in_data)

      # Allocate temporary output file.
      with tempfile.NamedTemporaryFile(delete=False) as out_file:
        out_file_name = out_file.name

      if op.type in (common.OpType.BSDIFF, common.OpType.SOURCE_BSDIFF,
                     common.OpType.BROTLI_BSDIFF):
        # Invoke bspatch.
        bspatch_cmd = [self.bspatch_path, in_file_name, out_file_name,
                       patch_file_name]
        subprocess.check_call(bspatch_cmd)
      elif op.type == common.OpType.PUFFDIFF:
        # Invoke puffpatch.
        puffpatch_cmd = [self.puffpatch_path,
                         "--operation=puffpatch",
                         "--src_file=%s" % in_file_name,
                         "--dst_file=%s" % out_file_name,
                         "--patch_file=%s" % patch_file_name]
        subprocess.check_call(puffpatch_cmd)
      else:
        raise PayloadError("Unknown operation %s", op.type)

      # Read output.
      with open(out_file_name, 'rb') as out_file:
        out_data = out_file.read()
        if len(out_data) != op.dst_length:
          raise PayloadError(
              '%s: actual patched data length (%d) not as expected (%d)' %
              (op_name, len(out_data), op.dst_length))

      # Write output back to partition, with padding.
      unaligned_out_len = len(out_data) % block_size
      if unaligned_out_len:
        out_data += '\0' * (block_size - unaligned_out_len)
      _WriteExtents(new_part_file, out_data, op.dst_extents, block_size,
                    '%s.dst_extents' % op_name)

      # Delete input/output files.
      os.remove(in_file_name)
      os.remove(out_file_name)

    # Delete patch file.
    os.remove(patch_file_name)

  def _ApplyOperations(self, operations, base_name, old_part_file,
                       new_part_file, part_size):
    """Applies a sequence of update operations to a partition.

    This assumes an in-place update semantics for MOVE and BSDIFF, namely all
    reads are performed first, then the data is processed and written back to
    the same file.

    Args:
      operations: the sequence of operations
      base_name: the name of the operation sequence
      old_part_file: the old partition file object, open for reading/writing
      new_part_file: the new partition file object, open for reading/writing
      part_size: the partition size

    Raises:
      PayloadError if anything goes wrong while processing the payload.
    """
    for op, op_name in common.OperationIter(operations, base_name):
      # Read data blob.
      data = self.payload.ReadDataBlob(op.data_offset, op.data_length)

      if op.type in (common.OpType.REPLACE, common.OpType.REPLACE_BZ,
                     common.OpType.REPLACE_XZ):
        self._ApplyReplaceOperation(op, op_name, data, new_part_file, part_size)
      elif op.type == common.OpType.MOVE:
        self._ApplyMoveOperation(op, op_name, new_part_file)
      elif op.type == common.OpType.ZERO:
        self._ApplyZeroOperation(op, op_name, new_part_file)
      elif op.type == common.OpType.BSDIFF:
        self._ApplyDiffOperation(op, op_name, data, new_part_file,
                                 new_part_file)
      elif op.type == common.OpType.SOURCE_COPY:
        self._ApplySourceCopyOperation(op, op_name, old_part_file,
                                       new_part_file)
      elif op.type in (common.OpType.SOURCE_BSDIFF, common.OpType.PUFFDIFF,
                       common.OpType.BROTLI_BSDIFF):
        self._ApplyDiffOperation(op, op_name, data, old_part_file,
                                 new_part_file)
      else:
        raise PayloadError('%s: unknown operation type (%d)' %
                           (op_name, op.type))

  def _ApplyToPartition(self, operations, part_name, base_name,
                        new_part_file_name, new_part_info,
                        old_part_file_name=None, old_part_info=None):
    """Applies an update to a partition.

    Args:
      operations: the sequence of update operations to apply
      part_name: the name of the partition, for error reporting
      base_name: the name of the operation sequence
      new_part_file_name: file name to write partition data to
      new_part_info: size and expected hash of dest partition
      old_part_file_name: file name of source partition (optional)
      old_part_info: size and expected hash of source partition (optional)

    Raises:
      PayloadError if anything goes wrong with the update.
    """
    # Do we have a source partition?
    if old_part_file_name:
      # Verify the source partition.
      with open(old_part_file_name, 'rb') as old_part_file:
        _VerifySha256(old_part_file, old_part_info.hash,
                      'old ' + part_name, length=old_part_info.size)
      new_part_file_mode = 'r+b'
      if self.minor_version == common.INPLACE_MINOR_PAYLOAD_VERSION:
        # Copy the src partition to the dst one; make sure we don't truncate it.
        shutil.copyfile(old_part_file_name, new_part_file_name)
      elif self.minor_version >= common.SOURCE_MINOR_PAYLOAD_VERSION:
        # In minor version >= 2, we don't want to copy the partitions, so
        # instead just make the new partition file.
        open(new_part_file_name, 'w').close()
      else:
        raise PayloadError("Unknown minor version: %d" % self.minor_version)
    else:
      # We need to create/truncate the dst partition file.
      new_part_file_mode = 'w+b'

    # Apply operations.
    with open(new_part_file_name, new_part_file_mode) as new_part_file:
      old_part_file = (open(old_part_file_name, 'r+b')
                       if old_part_file_name else None)
      try:
        self._ApplyOperations(operations, base_name, old_part_file,
                              new_part_file, new_part_info.size)
      finally:
        if old_part_file:
          old_part_file.close()

      # Truncate the result, if so instructed.
      if self.truncate_to_expected_size:
        new_part_file.seek(0, 2)
        if new_part_file.tell() > new_part_info.size:
          new_part_file.seek(new_part_info.size)
          new_part_file.truncate()

    # Verify the resulting partition.
    with open(new_part_file_name, 'rb') as new_part_file:
      _VerifySha256(new_part_file, new_part_info.hash,
                    'new ' + part_name, length=new_part_info.size)

  def Run(self, new_parts, old_parts=None):
    """Applier entry point, invoking all update operations.

    Args:
      new_parts: map of partition name to dest partition file
      old_parts: map of partition name to source partition file (optional)

    Raises:
      PayloadError if payload application failed.
    """
    if old_parts is None:
      old_parts = {}

    self.payload.ResetFile()

    new_part_info = {}
    old_part_info = {}
    install_operations = []

    manifest = self.payload.manifest
    if self.payload.header.version == 1:
      for real_name, proto_name in common.CROS_PARTITIONS:
        new_part_info[real_name] = getattr(manifest, 'new_%s_info' % proto_name)
        old_part_info[real_name] = getattr(manifest, 'old_%s_info' % proto_name)

      install_operations.append((common.ROOTFS, manifest.install_operations))
      install_operations.append((common.KERNEL,
                                 manifest.kernel_install_operations))
    else:
      for part in manifest.partitions:
        name = part.partition_name
        new_part_info[name] = part.new_partition_info
        old_part_info[name] = part.old_partition_info
        install_operations.append((name, part.operations))

    part_names = set(new_part_info.keys())  # Equivalently, old_part_info.keys()

    # Make sure the arguments are sane and match the payload.
    new_part_names = set(new_parts.keys())
    if new_part_names != part_names:
      raise PayloadError('missing dst partition(s) %s' %
                         ', '.join(part_names - new_part_names))

    old_part_names = set(old_parts.keys())
    if part_names - old_part_names:
      if self.payload.IsDelta():
        raise PayloadError('trying to apply a delta update without src '
                           'partition(s) %s' %
                           ', '.join(part_names - old_part_names))
    elif old_part_names == part_names:
      if self.payload.IsFull():
        raise PayloadError('trying to apply a full update onto src partitions')
    else:
      raise PayloadError('not all src partitions provided')

    for name, operations in install_operations:
      # Apply update to partition.
      self._ApplyToPartition(
          operations, name, '%s_install_operations' % name, new_parts[name],
          new_part_info[name], old_parts.get(name, None), old_part_info[name])
