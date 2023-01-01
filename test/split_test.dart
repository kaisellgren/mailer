import 'dart:convert';

import 'package:mailer/src/smtp/internal_representation/conversion.dart';
import 'package:test/test.dart';

class _TestCase {
  final List<int> testString;
  final int splitAt;
  final List<List<int>> splitStrings;

  _TestCase._(this.testString, this.splitAt, this.splitStrings);

  factory _TestCase(String testString, int splitAt, List<String> splitStrings) {
    var testStringBytes = utf8.encode(testString);
    var splitStringBytes =
        splitStrings.map(utf8.encode).toList(growable: false);
    return _TestCase._(testStringBytes, splitAt, splitStringBytes);
  }
}

// Test with 4 byte unicode characters.
final List<_TestCase> _testCases = [
  _TestCase('1234567890', 5, ['12345', '67890']),
  _TestCase('𠜎𠜱𠝹𠱓𠱸', 1, ['𠜎', '𠜱', '𠝹', '𠱓', '𠱸']),
  _TestCase('𠜎𠜱𠝹𠱓𠱸', 2, ['𠜎', '𠜱', '𠝹', '𠱓', '𠱸']),
  _TestCase('𠜎𠜱𠝹𠱓𠱸', 3, ['𠜎', '𠜱', '𠝹', '𠱓', '𠱸']),
  _TestCase('𠜎𠜱𠝹𠱓𠱸', 4, ['𠜎', '𠜱', '𠝹', '𠱓', '𠱸']),
  _TestCase('𠜎𠜱𠝹𠱓𠱸', 5, ['𠜎', '𠜱', '𠝹', '𠱓', '𠱸']),
  _TestCase('𠜎𠜱𠝹𠱓𠱸', 6, ['𠜎', '𠜱', '𠝹', '𠱓', '𠱸']),
  _TestCase('𠜎𠜱𠝹𠱓𠱸', 7, ['𠜎', '𠜱', '𠝹', '𠱓', '𠱸']),
  _TestCase('𠜎𠜱𠝹𠱓𠱸', 8, ['𠜎𠜱', '𠝹𠱓', '𠱸']),
  _TestCase('a𠜎𠜱𠝹𠱓𠱸', 4, ['a', '𠜎', '𠜱', '𠝹', '𠱓', '𠱸']),
  _TestCase('a𠜎𠜱𠝹𠱓𠱸b', 4, ['a', '𠜎', '𠜱', '𠝹', '𠱓', '𠱸', 'b']),
  _TestCase('a𠜎𠜱𠝹𠱓𠱸b', 5, ['a𠜎', '𠜱', '𠝹', '𠱓', '𠱸b']),
  _TestCase('a𠜎𠜱𠝹𠱓𠱸b', 6, ['a𠜎', '𠜱', '𠝹', '𠱓', '𠱸b']),
  _TestCase('aaa𠜎𠜱𠝹𠱓𠱸b', 6, ['aaa', '𠜎', '𠜱', '𠝹', '𠱓', '𠱸b']),
];

void main() async {
  var i = 0;
  for (var tc in _testCases) {
    test('Split on utf8-borders (${i++})',
        () async => expect(split(tc.testString, tc.splitAt), tc.splitStrings));
  }
}
