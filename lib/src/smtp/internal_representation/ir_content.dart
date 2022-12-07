part of 'internal_representation.dart';

// We will try to build our emails using the following structure:
// (from https://stackoverflow.com/questions/3902455/mail-multipart-alternative-vs-multipart-mixed)
// mixed
//   alternative
//     text
//     related
//       html
//       inline image
//       inline image
//   attachment
//   attachment
enum _MultipartType { alternative, mixed, related }

abstract class _IRContent extends _IROutput {
  final List<_IRHeader> _header = [];

  Stream<List<int>> _outH(_IRMetaInformation metaInformation) async* {
    for (var hs in _header.map((h) => h.out(metaInformation))) {
      yield* hs;
    }
  }

  Stream<List<int>> _out64(
      Stream<List<int>> content, _IRMetaInformation irMetaInformation) async* {
    yield* _outH(irMetaInformation);
    yield eol8;
    yield* convert.base64.encoder
        .bind(content)
        .transform(convert.ascii.encoder)
        .transform(StreamSplitter(splitOverLength, maxLineLength));
    yield eol8;
    yield eol8;
  }
}

abstract class _IRContentPart extends _IRContent {
  bool _active = false;
  final String _boundary = _buildBoundary();
  late Iterable<_IRContent> _content;

  List<int> _boundaryStart(String boundary) => to8('--$boundary$eol');

  List<int> _boundaryEnd(String boundary) => to8('--$boundary--$eol');

  // We don't want to expose the number of sent emails.
  // Only use the counter, if milliseconds hasn't changed.
  static int _counter = 0;
  static int? _prevTimestamp;

  static String _buildBoundary() {
    var now = DateTime.now().millisecondsSinceEpoch;
    if (now != _prevTimestamp) _counter = 0;
    _prevTimestamp = now;
    return 'mailer-?=_${_counter++}-$now';
  }

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) async* {
    // If not active, don't output anything and output the nested content
    // directly.
    if (!_active) {
      assert(_content.length == 1);
      yield* _content.first.out(irMetaInformation);
      return;
    }

    // If we are active output headers and then surround embedded contents
    // with boundary lines.
    yield* _outH(irMetaInformation);
    yield eol8;
    for (var part in _content) {
      yield _boundaryStart(_boundary);
      yield* part.out(irMetaInformation);
    }
    yield _boundaryEnd(_boundary);
    yield eol8;
  }
}

Iterable<T> _follow<T>(T t, Iterable<T> ts) sync* {
  yield t;
  yield* ts;
}

class _IRContentPartMixed extends _IRContentPart {
  _IRContentPartMixed(Message message, Iterable<_IRHeader> header) {
    var attachments = message.attachments;
    var attached = attachments.where((a) => a.location == Location.attachment);

    _active = attached.isNotEmpty;

    if (_active) {
      _header.addAll(header);
      _header.add(_IRHeaderContentType(_boundary, _MultipartType.mixed));
      _IRContent contentAlternative = _IRContentPartAlternative(message, []);
      var contentAttachments = attached.map((a) => _IRContentAttachment(a));
      _content = _follow(contentAlternative, contentAttachments);
    } else {
      _content = [_IRContentPartAlternative(message, header)];
    }
  }
}

class _IRContentPartAlternative extends _IRContentPart {
  _IRContentPartAlternative(Message message, Iterable<_IRHeader> header) {
    var attachments = message.attachments;
    var hasEmbedded = attachments.any((a) => a.location == Location.inline);

    _active = message.text != null && (message.html != null || hasEmbedded);

    if (_active) {
      _header.addAll(header);
      _header.add(_IRHeaderContentType(_boundary, _MultipartType.alternative));
      var contentTxt = _IRContentText(message.text, _IRTextType.plain, []);
      var contentRelated = _IRContentPartRelated(message, []);
      _content = [contentTxt, contentRelated];
    } else if (message.text != null) {
      // text only
      _content = [_IRContentText(message.text, _IRTextType.plain, header)];
    } else {
      // html only
      _content = [_IRContentPartRelated(message, header)];
    }
  }
}

class _IRContentPartRelated extends _IRContentPart {
  _IRContentPartRelated(Message message, Iterable<_IRHeader> header) {
    var attachments = message.attachments;
    var embedded = attachments.where((a) => a.location == Location.inline);

    _active = embedded.isNotEmpty;

    if (_active) {
      _header.addAll(header);
      _header.add(_IRHeaderContentType(_boundary, _MultipartType.related));
      _IRContent contentHtml =
          _IRContentText(message.html, _IRTextType.html, []);
      var contentAttachments = embedded.map((a) => _IRContentAttachment(a));
      _content = _follow(contentHtml, contentAttachments);
    } else {
      _content = [_IRContentText(message.html, _IRTextType.html, header)];
    }
  }
}

class _IRContentAttachment extends _IRContent {
  final Attachment _attachment;

  _IRContentAttachment(this._attachment) {
    final contentType = _attachment.contentType;
    final filename = _attachment.fileName;

    _header.add(_IRHeaderText('content-type', contentType));
    _header.add(_IRHeaderText('content-transfer-encoding', 'base64'));

    if ((_attachment.cid ?? '').isNotEmpty) {
      _header.add(_IRHeaderText('content-id', _attachment.cid!));
    }

    final parms = <String, String>{};
    if ((filename ?? '').isNotEmpty) parms['filename'] = filename!;
    _header.add(_IRHeaderText(
        'content-disposition', _describeEnum(_attachment.location), parms));

    // Add additional headers set by the user.
    for (final headerEntry in _attachment.additionalHeaders.entries) {
      _header
          .add(_IRHeaderText(headerEntry.key.toLowerCase(), headerEntry.value));
    }
  }

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) {
    return _out64(_attachment.asStream(), irMetaInformation);
  }
}

enum _IRTextType { plain, html }

class _IRContentText extends _IRContent {
  String _text = '';

  _IRContentText(
      String? text, _IRTextType textType, Iterable<_IRHeader> header) {
    _header.addAll(header);
    var type = _describeEnum(textType);
    _header.add(_IRHeaderText('content-type', 'text/$type; charset=utf-8'));
    _header.add(_IRHeaderText('content-transfer-encoding', 'base64'));

    _text = text ?? '';
  }

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) {
    Stream<String> addEol(String s) async* {
      yield s;
      yield eol;
    }

    return _out64(
        Stream.fromIterable([_text])
            .transform(convert.LineSplitter())
            .asyncExpand(addEol) // Replace all eols with \r\n → canonical form.
            .transform(convert.utf8.encoder),
        irMetaInformation);
  }
}
