import 'address.dart';
import 'attachment.dart';

/// This class represents an e-mail that can be sent to someone/some people.
///
/// Use [text] to specify plaintext body or [html] to specify HTML body.
/// Use both to provide a fallback for text-only email clients.
///
/// The envelope 'MAIL FROM:' and 'RCPT TO:' are extracted from [from] and
/// [recipients], [ccRecipients] and [bccRecipients].
///
/// If [envelopeFrom] is not null it is used instead for the 'MAIL FROM:'
/// envelope SMTP command.
///
/// If [envelopeTos] is not null it is used instead for the 'RCPT TO:' commands.
/// Note that in this case the [bccRecipients] list is completely ignored.
///
/// Setting the [from] address is required!  You may use a group address
/// (`Group:;`) if you don't want to provide an address.  However some (/most?)
/// smtp servers will use your login address in that case.
///
/// The `From:`, `To:`, `Cc:` and `Subject:` headers are build from the
/// corresponding fields, unless a [headers] entry exists.
///
/// See [Attachment] for how to reference inline-attachments.
class Message {
  String? envelopeFrom;
  List<String>? envelopeTos;

  /// Allowed types are String and Address
  /// String must be a simple email-address.
  ///
  /// There is no parsing for name / mail-address pairs!
  /// Always use Address in this case.  (Otherwise we might incorrectly encode
  /// the name / mail-address pair with base64.)
  dynamic from;
  Address get fromAsAddress => _asAddresses([from]).first;

  /// See [from] for allowed types.
  List<dynamic> recipients = [];
  Iterable<Address> get recipientsAsAddresses => _asAddresses(recipients);

  /// See [from] for allowed types.
  List<dynamic> ccRecipients = [];
  Iterable<Address> get ccsAsAddresses => _asAddresses(ccRecipients);

  /// See [from] for allowed types.
  List<dynamic> bccRecipients = [];
  Iterable<Address> get bccsAsAddresses => _asAddresses(bccRecipients);

  /// Allowed values are String, Address, Iterable<Address>, Iterable<String> or
  /// DateTime.
  ///
  /// Iterable<String> is only allowed if all Strings are email-addresses .
  ///
  /// If a String contains an @ it is treated like an email-address.
  ///
  /// There is no parsing for name / mail-address pairs!
  /// Always use Address in this case.  (Otherwise we might incorrectly encode
  /// the name / mail-address pair with base64.)
  ///
  /// base64 encoding is applied for:
  /// * Strings containing non-ascii chars
  /// * Strings which are too long
  /// * Address.names if they contain non-ascii chars
  /// * Address.names if they are too long
  Map<String, dynamic> headers = {};

  String? subject;
  String? text;
  String? html;
  List<Attachment> attachments = [];

  static Iterable<Address> _asAddresses(Iterable<dynamic> adrs) =>
      adrs.map((a) => a is String ? Address(a) : a as Address);
}
