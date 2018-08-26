part of 'internal_representation.dart';

abstract class _IRHeader extends _IROutput {
  final String _name;

  Stream<List<int>> _outValue(String value) =>
      Stream.fromIterable([_name, ': ', value, eol].map(utf8.encode));

  /*
  Stream<List<int>> _outValue8(List<int> value) => Stream.fromIterable(
      [_name, ': '].map(utf8.encode).followedBy([value, _eol8]));
      */

  _IRHeader(this._name);
}

class _IRHeaderText extends _IRHeader {
  String _value;

  _IRHeaderText(String name, this._value) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outValue(_value);
}

class _IRHeaderAddress extends _IRHeader {
  Address _address;

  _IRHeaderAddress(String name, this._address) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outValue(_addressToString([_address]).first);
}

class _IRHeaderAddresses extends _IRHeader {
  List<Address> _addresses;

  _IRHeaderAddresses(String name, this._addresses) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outValue(_addressToString(_addresses).join(', '));
}

class _IRHeaderContentType extends _IRHeader {
  String _boundary;
  _MultipartType _multipartType;

  _IRHeaderContentType(this._boundary, this._multipartType) : super('content-type');

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) {
    return _outValue('multipart/${_describeEnum(_multipartType)};boundary="$_boundary"');
  }
}

class _IRHeaderDate extends _IRHeader {
  final DateTime _dateTime;

  static final DateFormat _dateFormat =
      DateFormat('EEE, dd MMM yyyy HH:mm:ss +0000');

  _IRHeaderDate(String name, this._dateTime) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outValue(_dateFormat.format(_dateTime.toUtc()));
}

Iterable<_IRHeader> _buildHeaders(Message message) {
  const noCustom = ['content-type', 'mime-version'];

  final headers = <_IRHeader>[];
  var msgHeaders = message.headers;

  // Add all custom headers which are not in [noCustom].
  msgHeaders.forEach((name, value) {
    if (noCustom.contains(name)) return;
    headers.add(_IRHeaderText(name, value));
  });

  if (!msgHeaders.containsKey('subject') && message.subject != null)
    headers.add(_IRHeaderText('subject', message.subject));

  if (!msgHeaders.containsKey('from'))
    headers.add(_IRHeaderAddress('from', message.from));

  if (!msgHeaders.containsKey('to')) {
    var tos = message.recipients ?? [];
    if (tos.isNotEmpty) headers.add(_IRHeaderAddresses('to', tos));
  }

  if (!msgHeaders.containsKey('cc')) {
    var ccs = message.ccRecipients ?? [];
    if (ccs.isNotEmpty) headers.add(_IRHeaderAddresses('cc', ccs));
  }

  if (!msgHeaders.containsKey('date'))
    headers.add(_IRHeaderDate('date', DateTime.now()));

  if (!msgHeaders.containsKey('x-mailer'))
    headers.add(_IRHeaderText('x-mailer', 'Dart Mailer library 2'));

  headers.add(_IRHeaderText('mime-version', '1.0'));

  return headers;
}
