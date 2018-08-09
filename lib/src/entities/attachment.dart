import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

