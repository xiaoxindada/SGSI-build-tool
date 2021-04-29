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

"""Unit tests for histogram.py."""

import unittest

from update_payload import format_utils
from update_payload import histogram


class HistogramTest(unittest.TestCase):
  """ Tests histogram"""

  @staticmethod
  def AddHumanReadableSize(size):
    fmt = format_utils.BytesToHumanReadable(size)
    return '%s (%s)' % (size, fmt) if fmt else str(size)

  def CompareToExpectedDefault(self, actual_str):
    expected_str = (
        'Yes |################    | 5 (83.3%)\n'
        'No  |###                 | 1 (16.6%)'
    )
    self.assertEqual(actual_str, expected_str)

  def testExampleHistogram(self):
    self.CompareToExpectedDefault(str(histogram.Histogram(
        [('Yes', 5), ('No', 1)])))

  def testFromCountDict(self):
    self.CompareToExpectedDefault(str(histogram.Histogram.FromCountDict(
        {'Yes': 5, 'No': 1})))

  def testFromKeyList(self):
    self.CompareToExpectedDefault(str(histogram.Histogram.FromKeyList(
        ['Yes', 'Yes', 'No', 'Yes', 'Yes', 'Yes'])))

  def testCustomScale(self):
    expected_str = (
        'Yes |#### | 5 (83.3%)\n'
        'No  |     | 1 (16.6%)'
    )
    actual_str = str(histogram.Histogram([('Yes', 5), ('No', 1)], scale=5))
    self.assertEqual(actual_str, expected_str)

  def testCustomFormatter(self):
    expected_str = (
        'Yes |################    | 5000 (4.8 KiB) (83.3%)\n'
        'No  |###                 | 1000 (16.6%)'
    )
    actual_str = str(histogram.Histogram(
        [('Yes', 5000), ('No', 1000)], formatter=self.AddHumanReadableSize))
    self.assertEqual(actual_str, expected_str)


if __name__ == '__main__':
  unittest.main()
