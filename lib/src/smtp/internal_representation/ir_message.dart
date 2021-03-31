part of 'internal_representation.dart';

class IRMessage {
  final Logger _logger = Logger('IRMessage');
  final Message? _message;
  late _IRContent _content;

  // Possibly throws.
  IRMessage(this._message) {
    var headers = _buildHeaders(_message!);
    _content = _IRContentPartMixed(_message!, headers);
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

  String get envelopeFrom =>
      _message!.envelopeFrom ?? _message!.fromAsAddress.mailAddress;

  Stream<List<int>> data(Capabilities capabilities) =>
      _content.out(_IRMetaInformation(capabilities)).map((s) {
        _logger.finest('«${convert.utf8.decoder.convert(s)}»');
        return s;
      });
}

class InvalidHeaderException implements Exception {
  String message;

  InvalidHeaderException(this.message);
}
