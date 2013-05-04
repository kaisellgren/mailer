part of mailer;

/**
 * This class represents an envelope that can be sent to someone/some people.
 *
 * Use [text] to specify plaintext body or [html] to specify HTML body. Use both to provide a fallback for old email clients.
 *
 * Recipients are defined as a [List] of [String]s.
 */
class Envelope {
  List<String> recipients = [];
  List<Attachment> attachments = [];
  String from = 'anonymous@${Platform.localHostname}';
  String subject;
  String text;
  String html;
  String identityString = 'mailer';
  Encoding encoding = Encoding.UTF_8;

  int _counter = 0;

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

    data = '${data}X-Mailer: Dart Mailer library\r\n';
    data = '${data}Mime-Version: 1.0\r\n';

    // Create boundary string.
    var boundary = '$identityString-?=_${++_counter}-${new DateTime.now().millisecondsSinceEpoch}';

    // Alternative or mixed?
    var multipartType = html != null && text != null ? 'alternative' : 'mixed';

    data = '${data}Content-Type: multipart/$multipartType; boundary="$boundary"\r\n';

    // Insert text message.
    if (text != null) {
      data = '${data}--$boundary\r\n';
      data = '${data}Content-Type: text/plain; charset="${encoding.name}"\r\n';
      data = '${data}Content-Transfer-Encoding: 7bit\r\n\r\n';
      data = '$data${_chunkSplit(text)}\r\n\r\n';
    }

    // Insert HTML message.
    if (html != null) {
      data = '${data}--$boundary\r\n';
      data = '${data}Content-Type: text/html; charset="${encoding.name}"\r\n';
      data = '${data}Content-Transfer-Encoding: 7bit\r\n\r\n';
      data = '$data${_chunkSplit(html)}\r\n\r\n';
    }

    // Add all attachments.
    attachments.forEach((attachment) {
      var filename = new Path(attachment.file.path).filename;

      // Create a chunk'd (76 chars per line) base64 string.
      var contents = _chunkSplit(CryptoUtils.bytesToBase64(attachment.file.readAsBytesSync()));

      data = '${data}--$boundary\r\n';
      data = '${data}Content-Type: ${getContentType(filename: attachment.file.path)}; name="$filename"\r\n';
      data = '${data}Content-Transfer-Encoding: base64\r\n';
      data = '${data}Content-Disposition: attachment; filename="$filename"\r\n\r\n';
      data = '$data${contents}\r\n\r\n';
    });

    data = '${data}--$boundary--\r\n\r\n.';

    return data;
  }
}