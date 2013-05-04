part of mailer;

/**
 * Sanitizes a generic header value.
 */
String _sanitizeField(String value) {
  if (value == null) return '';

  return value.replaceAll(new RegExp('(\\r|\\n|\\t)+', caseSensitive: false), '');
}

/**
 * Sanitizes the email header value.
 */
String _sanitizeEmail(String value) {
  if (value == null) return '';

  return value.replaceAll(new RegExp('(\\r|\\n|\\t|"|,|<|>)+', caseSensitive: false), '');
}

/**
 * Sanitizes the name header value.
 */
String _sanitizeName(String value) {
  return _sanitizeField(value)
    .replaceAll('"', "'")
    .replaceAll('<', '[')
    .replaceAll('>', ']');
}

/**
 * Splits the content to multiple lines ensuring that each line is no more than [length].
 */
String _chunkSplit(String data, [int length = 76]) {
  String result = '';

  var linesNeeded = (data.length / length).ceil();

  for (var i = 0; i < linesNeeded; i++) {
    result = '$result${data.substring(i * 76, (i * 76 + 76).clamp(0, data.length))}\r\n';
  }

  return result.substring(0, result.length - 2);
}