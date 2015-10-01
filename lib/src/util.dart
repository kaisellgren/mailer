part of mailer;

/**
 * Sanitizes a generic header value.
 */
String _sanitizeField(String value) {
  if (value == null) return '';

  return value.replaceAll(new RegExp('(\\r|\\n|\\t)+', caseSensitive: false), '');
}
