part of mailer;

/**
 * This class represents an envelope to send to someone/some people.
 *
 * Use [text] to specify plaintext body or [html] to specify HTML body. Use both to provide a fallback for old email clients.
 */
class Envelope {
  List<String> recipients = [];
  String from = 'anonymous@${Platform.localHostname}';
  String subject;
  String text;
  String html;

  /**
   * Writes the envelope as HTML data/body.
   *
   * Automatically sanitizes all fields.
   */
  String toString() {
    var data = '';

    if (subject != null) data = '${data}Subject: ${_sanitizeField(subject)}\r\n';

    if (from != null) data = '${data}From: ${_sanitizeEmail(from)}\r\n';

    if (recipients != null && recipients.length > 0) {
      var to = recipients.map((recipient) => _sanitizeEmail(recipient)).toList().join(',');
      data = '${data}To: $to\r\n';
    }

    data = '$data$text\r\n.\r\n';

    return data;
  }
}