import 'dart:async';
import 'dart:convert' as convert;

import 'package:logging/logging.dart';

final Logger _logger = Logger('conversion');

const String eol = '\r\n';

List<int> to8(String s) => convert.utf8.encode(s);
final List<int> eol8 = to8(eol);

bool _isMultiByteContinuationByte(int b) {
  // MultiByte continuation bytes are 0b10XXXXXX.
  return b >= 128 && b < 192;
}

/// Split [data] into chunks not splitting multi-byte utf8 chars.
///
/// If [maxLength] is provided returns chunks where the maximum length is
/// at most [maxLength].  (Overrides constructor argument).
///
/// If [maxLength] < 4 and there is a longer multiByte character the returned
/// chunk will be the complete multiByte and therefore possibly too long.
//
// UTF8 multi-byte rules (copied from:
// https://stackoverflow.com/questions/9356169/utf-8-continuation-bytes)
//
// The basic rules are this:
//    If a byte starts with a 0 bit, it's a single byte value less than 128.
//    If it starts with 11, it's the first byte of a multi-byte sequence and the
//      number of 1 bits at the start indicates how many bytes there are in
//      total (110xxxxx has two bytes, 1110xxxx has three and 11110xxx has four).
//    If it starts with 10, it's a continuation byte.
//
// A 4 byte multi byte character for example is:
// 11110000 10010000 10001101 10001000
// Note that the 2nd, 3rd and 4th byte all start with 10
Iterable<List<int>> split(List<int> data, int maxLength,
    {bool avoidUtf8Cut = true}) sync* {
  var start = 0;
  for (;;) {
    if (start >= data.length) break;

    // When using List.sublist "end" is not included in the output.
    var end = start + maxLength;
    if (end >= data.length) {
      yield data.sublist(start);
      break;
    }

    // Look at the character immediately following the chunk we would like to
    // return.
    var e = end; // We do not need to add 1!  e now "points" to the character
    // behind the characters a List.subList would return.
    // We have already verified that this character exists.
    while (avoidUtf8Cut && e > start && _isMultiByteContinuationByte(data[e])) {
      e--;
    }

    if (e == start) {
      // We must return the complete multiByte, even though it's longer than
      // the requested size.
      e = start + 1;
      while (e < data.length && _isMultiByteContinuationByte(data[e])) {
        e++;
      }
    }

    yield data.sublist(start, e);
    start = e;
  }
}

Stream<List<int>> _splitS(
    Stream<List<int>> dataS, int splitOver, int maxLength) {
  var currentLineLength = 0;
  var insertEol = false;

  var sc = StreamController<List<int>>();
  void processData(List<int> data) {
    _logger.finest('_splitS: <- ${data.length} bytes  currentLineLength: $currentLineLength');
    if (data.length + currentLineLength > maxLength) {
      var targetLength = maxLength ~/ 2;
      if (targetLength + currentLineLength > maxLength) {
        targetLength = maxLength - currentLineLength;
      }
      _logger.finest('_splitS: > maxLength ($maxLength) Splitting into $targetLength parts');
      split(data, targetLength, avoidUtf8Cut: false).forEach(processData);
    } else if (data.length + currentLineLength > splitOver) {
      _logger.finest('_splitS: inside splitOver ($splitOver) and maxLength ($maxLength) window.');
      // We are now over splitOver but not too long.  Perfect.
      if (insertEol) sc.add(eol8);
      sc.add(data);
      currentLineLength = 0;
      insertEol = true;
    } else {
      _logger.finest('_splitS: below splitOver ($splitOver).');
      // We are still below splitOver
      if (insertEol) sc.add(eol8);
      insertEol = false;

      sc.add(data);
      currentLineLength += data.length;
    }
  }

  dataS.listen(processData).onDone(() => sc.close());
  return sc.stream;
}

class StreamSplitter extends StreamTransformerBase<List<int>, List<int>> {
  final int maxLength;
  final int splitOverLength;

  StreamSplitter([this.splitOverLength = 80, this.maxLength = 800]);

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) =>
      _splitS(stream, splitOverLength, maxLength);
}
