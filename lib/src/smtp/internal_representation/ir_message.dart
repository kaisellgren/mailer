part of 'internal_representation.dart';

class IRMessage {
  final Message _message;
  _IRContent _content;

  // Possibly throws.
  IRMessage(this._message) {
    var headers = _buildHeaders(_message);
    _content = new _IRContentPartMixed(_message, headers);
  }

  Iterable<String> get envelopeTos {
    // All recipients.
    Iterable<String> envelopeTos = _message.envelopeTos ?? <String>[];
    if (envelopeTos.isEmpty) {
      envelopeTos = [
        _message.recipientsAsAddresses ?? [],
        _message.ccsAsAddresses ?? [],
        _message.bccsAsAddresses ?? []
      ]
          .expand((_) => _)
          .where((a) => a?.mailAddress != null)
          .map((a) => a.mailAddress);
    }
    return envelopeTos;
  }

  String get envelopeFrom =>
      _message.envelopeFrom ?? _message.fromAsAddress?.mailAddress ?? '';

  Stream<List<int>> data(Capabilities capabilities) =>
      _content.out(new _IRMetaInformation(capabilities));
}

class InvalidHeaderException implements Exception {
  String message;
  InvalidHeaderException(this.message);
}