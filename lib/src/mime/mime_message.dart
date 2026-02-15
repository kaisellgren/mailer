part of 'mime.dart';

class MimeMessage {
  final Message? _message;
  late Part _content;

  // Possibly throws.
  MimeMessage(this._message) {
    var headers = _buildHeaders(_message!);
    _content = MultipartMixed(_message!, headers);
  }

  Iterable<String?> get envelopeTos {
    // All recipients.
    Iterable<String?> envelopeTos = _message!.envelopeTos ?? [];

    if (envelopeTos.isEmpty) {
      envelopeTos = [
        ..._message!.recipientsAsAddresses,
        ..._message!.ccsAsAddresses,
        ..._message!.bccsAsAddresses
      ].map((a) => a.mailAddress);
    }
    return envelopeTos;
  }

  String get envelopeFrom => _message!.envelopeFrom ?? _message!.fromAsAddress.mailAddress;

  Stream<List<int>> data(Capabilities capabilities) =>
      _content.out(RenderContext(capabilities)).map((s) {
        if (s is String) {
          return convert.utf8.encode(s);
        }
        if (s is List<int>) {
          return s;
        }
        throw StateError('Did not expect ${s.runtimeType} in Part stream');
      });
}

class InvalidHeaderException implements Exception {
  String message;

  InvalidHeaderException(this.message);
}
