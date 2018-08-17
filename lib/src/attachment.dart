part of mailer;

/**
 * Represents a single email attachment.
 *
 * You may specify a [File], a [Stream] or just a [String] of [data].
 */
class Attachment {
  File file;
  Stream stream;
  String data;

  Attachment({this.file, this.stream, this.data}) {
    if (this.stream != null || this.data != null)
      throw 'Please use file-parameter for attachments. Others are not yet implemented.';
  }
}
