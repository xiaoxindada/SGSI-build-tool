#!/usr/bin/python2
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

"""Unit tests for format_utils.py."""

import unittest

from update_payload import format_utils


class NumToPercentTest(unittest.TestCase):
  """ Tests number conversion to percentage format."""
  def testHundredPercent(self):
    self.assertEqual(format_utils.NumToPercent(1, 1), '100%')

  def testOverHundredPercent(self):
    self.assertEqual(format_utils.NumToPercent(5, 2), '250%')

  def testWholePercent(self):
    self.assertEqual(format_utils.NumToPercent(3, 10), '30%')

  def testDefaultMinPrecision(self):
    self.assertEqual(format_utils.NumToPercent(3, 9), '33.3%')
    self.assertEqual(format_utils.NumToPercent(3, 900), '0.3%')

  def testDefaultMaxPrecision(self):
    self.assertEqual(format_utils.NumToPercent(3, 9000000), '0.00003%')
    self.assertEqual(format_utils.NumToPercent(3, 90000000), '0%')

  def testCustomMinPrecision(self):
    self.assertEqual(format_utils.NumToPercent(3, 9, min_precision=3),
                     '33.333%')
    self.assertEqual(format_utils.NumToPercent(3, 9, min_precision=0),
                     '33%')

  def testCustomMaxPrecision(self):
    self.assertEqual(format_utils.NumToPercent(3, 900, max_precision=1),
                     '0.3%')
    self.assertEqual(format_utils.NumToPercent(3, 9000, max_precision=1),
                     '0%')


class BytesToHumanReadableTest(unittest.TestCase):
  """ Tests number conversion to human readable format."""
  def testBaseTwo(self):
    self.assertEqual(format_utils.BytesToHumanReadable(0x1000), '4 KiB')
    self.assertEqual(format_utils.BytesToHumanReadable(0x400000), '4 MiB')
    self.assertEqual(format_utils.BytesToHumanReadable(0x100000000), '4 GiB')
    self.assertEqual(format_utils.BytesToHumanReadable(0x40000000000), '4 TiB')

  def testDecimal(self):
    self.assertEqual(format_utils.BytesToHumanReadable(5000, decimal=True),
                     '5 kB')
    self.assertEqual(format_utils.BytesToHumanReadable(5000000, decimal=True),
                     '5 MB')
    self.assertEqual(format_utils.BytesToHumanReadable(5000000000,
                                                       decimal=True),
                     '5 GB')

  def testDefaultPrecision(self):
    self.assertEqual(format_utils.BytesToHumanReadable(5000), '4.8 KiB')
    self.assertEqual(format_utils.BytesToHumanReadable(500000), '488.2 KiB')
    self.assertEqual(format_utils.BytesToHumanReadable(5000000), '4.7 MiB')

  def testCustomPrecision(self):
    self.assertEqual(format_utils.BytesToHumanReadable(5000, precision=3),
                     '4.882 KiB')
    self.assertEqual(format_utils.BytesToHumanReadable(500000, precision=0),
                     '488 KiB')
    self.assertEqual(format_utils.BytesToHumanReadable(5000000, precision=5),
                     '4.76837 MiB')


if __name__ == '__main__':
  unittest.main()
