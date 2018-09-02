import 'dart:async';
import 'dart:io';

import 'package:dart2_constant/convert.dart' as convert;
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart';

enum Location {
  /// Place attachment so that referencing them inside html is possible.
  inline,

  /// "Normal" attachment.
  attachment
}

/**
 * Represents a single email attachment.
 *
 * You may specify a [File], a [Stream] or just a [String] of [data].
 * [cid] allows you to specify the content id.
 *
 * When [location] is set to [Location.inline] The attachment (usually image)
 * can be referenced using:
 * `cid:yourCid`.  For instance: `<img src="cid:mylogo" />`
 */
abstract class Attachment {
  String cid;
  Location location = Location.attachment;
  String fileName;
  String contentType;
  Stream<List<int>> asStream();
}

class FileAttachment extends Attachment {
  final File _file;

  FileAttachment(this._file, {String contentType, String fileName}) {
    if (contentType == null) {
      this.contentType = mime.lookupMimeType(_file.path);
    }
    this.fileName = fileName ?? basename(_file.path);
  }

  @override
  Stream<List<int>> asStream() => _file.openRead();
}

class StreamAttachment extends Attachment {
  final Stream<List<int>> _stream;

  StreamAttachment(this._stream, String contentType, {String fileName}) {
    this.contentType = contentType;
    this.fileName = fileName;
  }

  @override
  Stream<List<int>> asStream() => _stream;
}

class StringAttachment extends Attachment {
  final String _data;

  StringAttachment(this._data, {String contentType, String fileName}) {
    if (contentType == null) {
      this.contentType = mime.lookupMimeType(fileName ?? 'unknown',
          headerBytes: convert.utf8.encode(_data));
    }
    this.fileName = fileName;
  }

  @override
  // There will be only one element in the stream: the utf8 encoded string.
  Stream<List<int>> asStream() =>
      new Stream.fromIterable([convert.utf8.encode(_data)]);
}
