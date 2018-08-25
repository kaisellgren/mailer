

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
Iterable<List<int>> split(List<int> data, [int maxLength]) sync* {
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
