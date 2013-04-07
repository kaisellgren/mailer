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