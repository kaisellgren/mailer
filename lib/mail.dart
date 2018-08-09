import 'dart:async';
import 'dart:convert';
import 'dart:io';

class Address {
  String name;
  String mailAddress;
}

/**
 * This class represents an e-mail that can be sent to someone/some people.
 *
 * Use [text] to specify plaintext body or [html] to specify HTML body.
 * Use both to provide a fallback for text-only email clients.
 *
 * The envelope 'MAIL FROM:' and 'RCPT TO:' are extracted from [from] and
 * [recipients], [ccRecipients] and [bccRecipients].
 *
 * If [SmtpMailFrom] is not null it is used instead for the 'MAIL FROM:'
 * envelope SMTP command.
 *
 * If [StmpRcptTo] is not null it is used instead for the 'RCPT TO:' commands.
 * Note that in this case the [bccRecipients] list is completely ignored.
 *
 * Setting the [from] address is required!  You may use a group address
 * (`Group:;`) if you don't want to provide an address.  However some (/most?)
 * smtp servers will use your login address in that case.
 */
class Mail {
  String SmtpMailFrom;
  List<String> StmpRcptTo;

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

/**
 * Represents a single email attachment.
 *
 * You may specify a [File], a [Stream] or just a [String] of [data].
 */
abstract class Attachment {
  Stream<List<int>> asStream();
}

class FileAttachment implements Attachment {
  final File _file;

  FileAttachment(this._file);

  @override
  Stream<List<int>> asStream() => _file.openRead();
}

class StreamAttachment implements Attachment {
  final Stream<List<int>> _stream;

  StreamAttachment(this._stream);

  @override
  Stream<List<int>> asStream() => _stream;
}

class StringAttachment implements Attachment {
  final String _data;

  StringAttachment(this._data);

  @override
  Stream<List<int>> asStream() => new Stream.fromIterable(UTF8.encode(_data));
}

class SendReport {
  final Mail mail;
  final bool sent;

  SendReport(this.mail, this.sent);
}
