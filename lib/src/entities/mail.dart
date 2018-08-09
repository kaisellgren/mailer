import 'address.dart';
import 'attachment.dart';

/**
 * This class represents an e-mail that can be sent to someone/some people.
 *
 * Use [text] to specify plaintext body or [html] to specify HTML body.
 * Use both to provide a fallback for text-only email clients.
 *
 * The envelope 'MAIL FROM:' and 'RCPT TO:' are extracted from [from] and
 * [recipients], [ccRecipients] and [bccRecipients].
 *
 * If [envelopeFrom] is not null it is used instead for the 'MAIL FROM:'
 * envelope SMTP command.
 *
 * If [envelopeTos] is not null it is used instead for the 'RCPT TO:' commands.
 * Note that in this case the [bccRecipients] list is completely ignored.
 *
 * Setting the [from] address is required!  You may use a group address
 * (`Group:;`) if you don't want to provide an address.  However some (/most?)
 * smtp servers will use your login address in that case.
 */
class Mail {
  String envelopeFrom;
  List<String> envelopeTos;

  Address from;
  List<Address> recipients = [];
  List<Address> ccRecipients = [];
  List<Address> bccRecipients = [];
  Map<String, String> headers = {};

  String subject;
  String text;
  String html;
  List<Attachment> attachments = [];
}

