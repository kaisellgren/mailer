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
      var data = '';

      if (subject != null) {
        data += 'Subject: ${_sanitizeField(subject)}\r\n';
      }

      if (from != null) {
        var fromData = _sanitizeEmail(from);

        if (fromName != null) {
          fromData = '$fromName <$fromData>';
        }

        data += 'From: $fromData\r\n';
      }

      if (recipients != null && recipients.length > 0) {
        var to = recipients.map((recipient) => _sanitizeEmail(recipient)).toList().join(',');
        data += 'To: $to\r\n';
      }

      data += 'X-Mailer: Dart Mailer library\r\n'
              'Mime-Version: 1.0\r\n';

      // Create boundary string.
      var boundary = '$identityString-?=_${++_counter}-${new DateTime.now().millisecondsSinceEpoch}';

      // Alternative or mixed?
      var multipartType = html != null && text != null ? 'alternative' : 'mixed';

      data += 'Content-Type: multipart/$multipartType; boundary="$boundary"\r\n';

      // Insert text message.
      if (text != null) {
        data += '--$boundary\r\n'
                'Content-Type: text/plain; charset="${encoding.name}"\r\n'
                'Content-Transfer-Encoding: 7bit\r\n\r\n'
                '$text\r\n\r\n';
      }

      // Insert HTML message.
      if (html != null) {
        data += '--$boundary\r\n'
                'Content-Type: text/html; charset="${encoding.name}"\r\n'
                'Content-Transfer-Encoding: 7bit\r\n\r\n'
                '$html\r\n\r\n';
      }

      // Add all attachments.
      return Future.forEach(attachments, (attachment) {
        var filename = basename(attachment.file.path);

        return attachment.file.readAsBytes().then((bytes) {
          // Create a chunk'd (76 chars per line) base64 string.
          var contents = CryptoUtils.bytesToBase64(bytes, addLineSeparator:true);

          data += '--$boundary\r\n'
                  'Content-Type: ${getContentType(filename: attachment.file.path)}; name="$filename"\r\n'
                  'Content-Transfer-Encoding: base64\r\n'
                  'Content-Disposition: attachment; filename="$filename"\r\n\r\n'
                  '${contents}\r\n\r\n';
        });
      }).then((_) {
        data += '--$boundary--\r\n\r\n.';

        return data;
      });
    });
  }
}
