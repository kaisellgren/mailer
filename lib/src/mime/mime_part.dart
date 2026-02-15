part of 'mime.dart';

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
enum MultipartType { alternative, mixed, related }

/// A MIME entity.
///
/// "Entity" is the technical MIME term, but we use "Part" here.
abstract class Part extends _MimeOutput {
  final List<Header> _header = [];

  String _renderHeaders(RenderContext renderContext) {
    var buffer = StringBuffer();
    for (var header in _header) {
      buffer.write(header.render(renderContext));
    }
    return buffer.toString();
  }

  Stream<Object> _outContent(Stream<List<int>> content, RenderContext renderContext) async* {
    ContentEncoder encoder;
    if (renderContext.capabilities.binaryMime) {
      encoder = BinaryContentEncoder();
    } else {
      encoder = Base64ContentEncoder();
    }

    yield _renderHeaders(renderContext);
    yield eol;
    yield* encoder.encode(content);
    yield eol;
    yield eol;
  }
}

abstract class ContentPart extends Part {
  bool _active = false;
  final String _boundary = _buildBoundary();
  late Iterable<Part> _content;

  String _boundaryStart(String boundary) => '--$boundary$eol';

  String _boundaryEnd(String boundary) => '--$boundary--$eol';

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
  Stream<Object> out(RenderContext renderContext) async* {
    // If not active, don't output anything and output the nested content
    // directly.
    if (!_active) {
      assert(_content.length == 1);
      yield* _content.first.out(renderContext);
      return;
    }

    // If we are active output headers and then surround embedded contents
    // with boundary lines.
    yield _renderHeaders(renderContext);
    yield eol;
    for (var part in _content) {
      yield _boundaryStart(_boundary);
      yield* part.out(renderContext);
    }
    yield _boundaryEnd(_boundary);
    yield eol;
  }
}

class MultipartMixed extends ContentPart {
  MultipartMixed(Message message, Iterable<Header> header) {
    var attachments = message.attachments;
    var attached = attachments.where((a) => a.location == Location.attachment);

    _active = attached.isNotEmpty;

    if (_active) {
      _header.addAll(header);
      _header.add(ContentTypeHeader(_boundary, MultipartType.mixed));
      Part contentAlternative = MultipartAlternative(message, []);
      var contentAttachments = attached.map((a) => AttachmentPart(a));
      _content = [contentAlternative, ...contentAttachments];
    } else {
      _content = [MultipartAlternative(message, header)];
    }
  }
}

class MultipartAlternative extends ContentPart {
  MultipartAlternative(Message message, Iterable<Header> header) {
    var attachments = message.attachments;
    var hasEmbedded = attachments.any((a) => a.location == Location.inline);

    _active = message.text != null && (message.html != null || hasEmbedded);

    if (_active) {
      _header.addAll(header);
      _header.add(ContentTypeHeader(_boundary, MultipartType.alternative));
      var contentTxt = TextPart(message.text, TextType.plain, []);
      var contentRelated = MultipartRelated(message, []);
      _content = [contentTxt, contentRelated];
    } else if (message.text != null) {
      // text only
      _content = [TextPart(message.text, TextType.plain, header)];
    } else {
      // html only
      _content = [MultipartRelated(message, header)];
    }
  }
}

class MultipartRelated extends ContentPart {
  MultipartRelated(Message message, Iterable<Header> header) {
    var attachments = message.attachments;
    var embedded = attachments.where((a) => a.location == Location.inline);

    _active = embedded.isNotEmpty;

    if (_active) {
      _header.addAll(header);
      _header.add(ContentTypeHeader(_boundary, MultipartType.related));
      Part contentHtml = TextPart(message.html, TextType.html, []);
      var contentAttachments = embedded.map((a) => AttachmentPart(a));
      _content = [contentHtml, ...contentAttachments];
    } else {
      _content = [TextPart(message.html, TextType.html, header)];
    }
  }
}

class AttachmentPart extends Part {
  final Attachment _attachment;

  AttachmentPart(this._attachment) {
    final contentType = _attachment.contentType;
    final filename = _attachment.fileName;

    _header.add(TextHeader('content-type', contentType));
    _header.add(DynamicHeader(
        'content-transfer-encoding', (info) => info.capabilities.binaryMime ? 'binary' : 'base64'));

    if ((_attachment.cid ?? '').isNotEmpty) {
      var cid = _attachment.cid!;
      if (!cid.startsWith('<')) cid = '<$cid';
      if (!cid.endsWith('>')) cid = '$cid>';
      _header.add(TextHeader('content-id', cid));
    }

    final parms = <String, String>{};
    if ((filename ?? '').isNotEmpty) parms['filename'] = filename!;
    _header.add(TextHeader('content-disposition', _attachment.location.name, parms));

    // Add additional headers set by the user.
    for (final headerEntry in _attachment.additionalHeaders.entries) {
      _header.add(TextHeader(headerEntry.key.toLowerCase(), headerEntry.value));
    }
  }

  @override
  Stream<Object> out(RenderContext renderContext) {
    return _outContent(_attachment.asStream(), renderContext);
  }
}

enum TextType { plain, html }

class TextPart extends Part {
  static final _eolRegex = RegExp(r'\r\n?|\n');

  String _text = '';

  TextPart(String? text, TextType textType, Iterable<Header> header) {
    _header.addAll(header);
    _header.add(TextHeader('content-type', 'text/${textType.name}; charset=utf-8'));
    _header.add(DynamicHeader(
        'content-transfer-encoding', (info) => info.capabilities.binaryMime ? 'binary' : 'base64'));

    _text = text ?? '';
  }

  @override
  Stream<Object> out(RenderContext renderContext) {
    // Replace all EOLs with \r\n (canonical form)
    var canonicalText = _text.split(_eolRegex).join(eol);
    if (canonicalText.isNotEmpty && !canonicalText.endsWith(eol)) {
      canonicalText += eol;
    }
    return _outContent(Stream.value(convert.utf8.encode(canonicalText)), renderContext);
  }
}
