part of 'internal_representation.dart';

class IRMessage {
  final Message _message;
  final _IRMetaInformation _irMetaInformation;

  IRMessage(this._message, Capabilities capabilities)
      : _irMetaInformation = new _IRMetaInformation(capabilities);

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

  Stream<List<int>> data() {
    // First build everything.
    // This is necessary as during build some metaInformation is filled,
    // which is used during the output phase.
    var headers = _buildHeaders(_message, _irMetaInformation);

    var content = _IRContentPartMixed(_message, headers);
    return content.out(_irMetaInformation);
  }
}
