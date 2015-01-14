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
  String fromName;
  String replyTo;
  String replyToName;
  String sender;
  String senderName;
  String subject;
  String text;
  String html;
  String identityString = 'mailer';
  Encoding encoding = UTF8;

  int _counter = 0;

  /**
   * Returns the envelope as a String that is suitable for use in SMTP DATA section.
   *
   * This method automatically sanitizes all fields.
   */
  Future<String> getContents() {
    return new Future(() {
      var buffer = new StringBuffer();

      if (subject != null) buffer.write('Subject: ${_sanitizeField(subject)}\n');

      if (from != null) {
        var fromData = _sanitizeEmail(from);

        if (fromName != null) {
          fromData = '$fromName <$fromData>';
        }

        buffer.write('From: $fromData\n');
      }

      if (replyTo != null) {
        var replyToData = _sanitizeEmail(replyTo);

        if (replyToName != null) {
          replyToData = '$replyToName <$replyToData>';
        }

        buffer.write('Reply-To: $replyToData\n');
      }

      if (sender != null) {
        var senderData = _sanitizeEmail(sender);

        if (senderName != null) {
          senderData = '$senderName <$senderData>';
        }

        buffer.write('Sender: $senderData\n');
      }

      if (recipients != null && recipients.length > 0) {
        var to = recipients.map((recipient) => _sanitizeEmail(recipient)).toList().join(',');
        buffer.write('To: $to\n');
      }

      // Since TimeZone is not implemented in DateFormat we need to use UTC for proper Date header generation time
      buffer.write('Date: ' + new DateFormat('EEE, dd MMM yyyy HH:mm:ss +0000').format(new DateTime.now().toUtc()) + '\n');
      buffer.write('X-Mailer: Dart Mailer library\n');
      buffer.write('Mime-Version: 1.0\n');

      // Create boundary string.
      var boundary = '$identityString-?=_${++_counter}-${new DateTime.now().millisecondsSinceEpoch}';

      // Alternative or mixed?
      var multipartType = html != null && text != null ? 'alternative' : 'mixed';

      buffer.write('Content-Type: multipart/$multipartType; boundary="$boundary"\n\n');

      // Insert text message.
      if (text != null) {
        buffer.write('--$boundary\n');
        buffer.write('Content-Type: text/plain; charset="${encoding.name}"\n');
        buffer.write('Content-Transfer-Encoding: 7bit\n\n');
        buffer.write('$text\n\n');
      }

      // Insert HTML message.
      if (html != null) {
        buffer.write('--$boundary\n');
        buffer.write('Content-Type: text/html; charset="${encoding.name}"\n');
        buffer.write('Content-Transfer-Encoding: 7bit\n\n');
        buffer.write('$html\n\n');
      }

      // Add all attachments.
      return Future.forEach(attachments, (attachment) {
        var filename = basename(attachment.file.path);

        return attachment.file.readAsBytes().then((bytes) {
          // Create a chunk'd (76 chars per line) base64 string.
          var contents = CryptoUtils.bytesToBase64(bytes, addLineSeparator: true);

          buffer.write('--$boundary\n');
          buffer.write('Content-Type: ${_getMimeType(attachment.file.path)}; name="$filename"\n');
          buffer.write('Content-Transfer-Encoding: base64\n');
          buffer.write('Content-Disposition: attachment; filename="$filename"\n\n');
          buffer.write('$contents\n\n');
        });
      }).then((_) {
        buffer.write('--$boundary--\n\r\n.'); // Note. the \r actually needs to be there.

        return buffer.toString();
      });
    });
  }
}

String _getMimeType(String path) {
  final mtype = lookupMimeType(path);
  return mtype != null ? mtype: 'application/octet-stream';
}
