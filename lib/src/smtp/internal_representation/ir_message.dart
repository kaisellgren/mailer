part of 'internal_representation.dart';

class IRMessage {
  final Message _message;

  IRMessage(this._message);

  Iterable<String> get envelopeTos {
    // All recipients.
    Iterable<String> envelopeTos = _message.envelopeTos ?? <String>[];
    if (envelopeTos.isEmpty) {
      envelopeTos = [
        _message.recipients ?? [],
        _message.ccRecipients ?? [],
        _message.bccRecipients ?? []
      ]
          .expand((_) => _)
          .where(((a) => a?.mailAddress != null))
          .map((a) => a.mailAddress);
    }
    return envelopeTos;
  }

  String get envelopeFrom =>
      _message.envelopeFrom ?? _message.from?.mailAddress ?? '';

  Stream<List<int>> data(Capabilities capabilities) {
    var headers = _buildHeaders(_message);
    var content = _IRContentPartMixed(_message, headers);
    return content.out(_IRMetaInformation(capabilities));
  }
}
