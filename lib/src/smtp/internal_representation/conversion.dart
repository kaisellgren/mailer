import 'dart:async';
import 'dart:convert' as convert;

const String eol = '\r\n';

List<int> to8(String s) => convert.utf8.encode(s);
final List<int> eol8 = to8(eol);

bool _isMultiByteContinuationByte(int b) {
  // MultiByte continuation bytes start are 0b10XXXXXX.
  return b >= 128 && b < 192;
}

/// Split [data] into chunks not splitting multi-byte utf8 chars.
///
/// If [maxLength] is provided returns chunks where the maximum length is
/// at most [maxLength].  (Overrides constructor argument).
///
/// If [maxLength] < 4 and there is a longer multiByte character the returned
/// chunk will be the complete multiByte and therefore possibly too long.
Iterable<List<int>> split(List<int> data, int maxLength,
    {bool avoidUtf8Cut = true}) sync* {
  int start = 0;
  for (;;) {
    int end = start + maxLength;
    if (end >= data.length) {
      yield data.sublist(start);
      break;
    }

    // Look at the character immediately following the chunk we would like to
    // return.
    int e = end + 1;
    while (avoidUtf8Cut && e > start && _isMultiByteContinuationByte(data[e])) {
      e--;
    }

    if (e == start) {
      // We must return the complete multiByte, even though it's longer than
      // the requested size.
      e = start + 1;
      while (_isMultiByteContinuationByte(data[e])) {
        e++;
      }
    }

    yield data.sublist(start, e);
    start = e;
  }
}

Stream<List<int>> _splitS(
    Stream<List<int>> dataS, int splitOver, int maxLength) {
  int currentLineLength = 0;

  var sc = StreamController<List<int>>();
  void processData(List<int> data) {
    if (data.length + currentLineLength > maxLength) {
      int targetLength = maxLength ~/ 2;
      if (targetLength + currentLineLength > maxLength) {
        targetLength = maxLength - currentLineLength;
      }
      split(data, targetLength, avoidUtf8Cut: false).forEach(processData);
    } else if (data.length + currentLineLength > splitOver) {
      // We are now over splitOver but not too long.  Perfect.
      sc.add(data);
      sc.add(eol8);
      currentLineLength = 0;
    } else {
      // We are still below splitOver
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
