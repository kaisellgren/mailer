import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart';

enum Location {
  /// Place attachment so that referencing them inside html is possible.
  inline,

  /// "Normal" attachment.
  attachment
}

/// Represents a single email attachment.
///
/// You may specify a [File], a [Stream] or just a [String] of [data].
/// [cid] allows you to specify the content id for html inlining.
///
/// When [location] is set to [Location.inline] The attachment (usually image)
/// can be referenced using:
/// `cid:yourCid`.  For instance: `<img src="cid:yourCid" />`
///
/// [cid] must contain an `@` and be inside `<` and `>`.
/// The cid: `<myImage@3.141>` can then be referenced inside your html as:
/// `<img src="cid:myImage@3.141">`
abstract class Attachment {
  String? cid;
  Location location = Location.attachment;
  String? fileName;
  late String contentType;

  /// Additional headers that will be added to the attachment after all of the standard headers are set.
  /// This is useful for adding, for example, "X-Attachment-Id" to an attachment, which is used by
  /// gmail when referencing an image in `<img src="cid:...">`.
  final Map<String, String> additionalHeaders = {};

  Stream<List<int>> asStream();
}

class FileAttachment extends Attachment {
  final File _file;

  FileAttachment(this._file, {String? contentType, String? fileName}) {
    this.contentType = contentType ??
        mime.lookupMimeType(_file.path) ??
        'application/octet-stream';
    this.fileName = fileName ?? basename(_file.path);
  }

  @override
  Stream<List<int>> asStream() => _file.openRead();
}

class StreamAttachment extends Attachment {
  final Stream<List<int>> _stream;

  StreamAttachment(this._stream, String contentType, {String? fileName}) {
    this.contentType = contentType;
    this.fileName = fileName;
  }

  @override
  Stream<List<int>> asStream() => _stream;
}

class StringAttachment extends Attachment {
  final String _data;

  StringAttachment(this._data, {String? contentType, String? fileName}) {
    this.contentType = contentType ??
        mime.lookupMimeType(fileName ?? 'abc.txt',
            headerBytes: convert.utf8.encode(_data)) ??
        'text/plain';
    this.fileName = fileName;
  }

  @override
  // There will be only one element in the stream: the utf8 encoded string.
  Stream<List<int>> asStream() =>
      Stream.fromIterable([convert.utf8.encode(_data)]);
}
