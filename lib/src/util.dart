
/// Consume the encode bytes (no line separators),
/// and produce a chunk'd (76 chars per line) string, separated by "\r\n".
String chunkEncodedBytes(String encoded) {
  if (encoded == null) return null;
  var chunked = new StringBuffer();
  int start = 0;
  int end = encoded.length;
  do {
    int next = start + 76;
    if (next > end) next = end;
    chunked.write(encoded.substring(start, next));
    chunked.write('\r\n');
    start = next;
  } while (start < encoded.length);
  return chunked.toString();
}

/**
 * Sanitizes a generic header value.
 */
String sanitizeField(String value) {
  if (value == null) return '';

  return value.replaceAll(new RegExp('(\\r|\\n|\\t)+', caseSensitive: false), '');
}
