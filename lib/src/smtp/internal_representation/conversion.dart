import 'dart:async';
import 'dart:convert';

const String eol = '\r\n';

List<int> to8(String s) => utf8.encode(s);
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
/// If [maxLength] < 4 and there is a longer multibyte character the returned
/// chunk will be the complete multibyte and therefore possibly too long.
Iterable<List<int>> split(List<int> data, [int maxLength = 80]) sync* {
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
    while (e > start && _isMultiByteContinuationByte(data[e])) {
      e--;
    }

    if (e == start) {
      // We must return the complete multibyte, even though it's longer than
      // the requested size.
      e = start + 1;
      while (_isMultiByteContinuationByte(data[e])) e++;
    }

    yield data.sublist(start, e - 1);
    start = e;
  }
}

Stream<List<int>> _splitS(Stream<List<int>> dataS, [int maxLength]) {
  List<int> remaining = [];
  var sc = StreamController<List<int>>();
  dataS.listen((d) {
    var sd = split(remaining.followedBy(d).toList(growable: false), maxLength);
    var it = sd.iterator;

    it.moveNext();
    for (var i = 0; i < sd.length - 1; i++) {
      sc.add(it.current);
      sc.add(eol8);
      it.moveNext();
    }
    remaining = it.current;
  }).onDone(() {
    if (remaining.isNotEmpty) sc.add(remaining);
    sc.close();
  });
  return sc.stream;
}

class StreamSplitter extends StreamTransformerBase<List<int>, List<int>> {
  final int maxLength;

  StreamSplitter([this.maxLength = null]);

  @override
  Stream<List<int>> bind(Stream<List<int>> stream) =>
      _splitS(stream, maxLength);
}
