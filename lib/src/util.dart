/// Consume the encode bytes (no line separators),
/// and produce a chunk'd (76 chars per line) string, separated by "\r\n".
chunkEncodedBytes(String encoded) {
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

  return value.replaceAll(_reField, ' ');
}

final RegExp _reField = new RegExp('(\\r|\\n|\\t)+');

/// Sanitizes a display name (of an email address).
String sanitizeName(String name) {
  if (name == null || (name = name.trim()).isEmpty) return null;

  return _reName.hasMatch(name) ? name : '"' + name.replaceAll('"', "'") + '"';
}

final RegExp _reName = new RegExp(r"^[- a-zA-Z0-9!#$%&'*+/=?^_`{|}~]*$");
