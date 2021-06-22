#!/bin/bash

# Copyrigh#!/bin/bash

# Copyright (C) 2021 Xiaoxindada <2245062854@qq.com>

LOCALDIR=`cd "$( dirname $0 )" && pwd`
cd $LOCALDIR
source ./bin.sh

bb="busybox"
testdir=$bin/boot_tools/test
unpacknootimg=$testdir/unpack_bootimg.py
mkbootimg=$testdir/mkbootimg.py
dumpimage=$testdir/dumpimage
cpio=$testdir/cpio
lz4=$testdir/lz4
vendor_bootdir=$LOCALDIR/vendor_boot
vendor_ramdiskdir=$vendor_bootdir/ramdisk

rm -rf $vendor_bootdir
rm -rf $vendor_ramdiskdir
mkdir -p $vendor_bootdir
mkdir -p $vendor_ramdiskdir

$unpacknootimg --boot_img "$LOCALDIR/vendor_boot.img" --out "$vendor_bootdir"

if (file $vendor_bootdir/vendor_ramdisk* | grep -qo "lz4") ;then
  $lz4 -d $vendor_bootdir/vendor_ramdisk* $vendor_bootdir/vendor_ramdisk.cpio
  cd $vendor_ramdiskdir
  $cpio -i --no-absolute-filenames < ../vendor_ramdisk.cpio
  rm -rf $vendor_bootdir/vendor_ramdisk.cpio
  cd $LOCALDIR
fi

if (file $vendor_bootdir/vendor_ramdisk* | grep -qo "gz") ;then
  mv $vendor_bootdir/vendor_ramdisk* $vendor_bootdir/vendor_ramdisk.gz
  $bb gunzip -c -k -f $vendor_bootdir/vendor_ramdisk.gz > $vendor_bootdir/vendor_ramdisk.cpio
  cd $vendor_ramdiskdir
  $cpio -i --no-absolute-filenames < ../vendor_ramdisk.cpio
  rm -rf $vendor_bootdir/vendor_ramdisk.cpio
  cd $LOCALDIR
fi
chmod 777 -R $vendor_bootdir

