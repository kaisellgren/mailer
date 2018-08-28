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
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) async* {
    final List<int> b64prefix = utf8.encode(' =?utf-8?B?');
    final List<int> b64postfix = utf8.encode('?=$eol');

    bool utf8Allowed = irMetaInformation.capabilities.smtpUtf8;

    if (_value.length > maxLineLength ||
        (!utf8Allowed && _value.contains(RegExp(r'[^\x20-\x7E]')))) {
      print('base64 encode');
      // Encode with base64.
      var nameLength = _name.length + 2;  // 'name: '
      var b64Length = b64prefix.length + b64postfix.length;
      var availableLengthForBase64 = maxEncodedLength - b64Length;

      // Length after base64: ceil(n / 3) * 4
      var lengthBeforeBase64 = (availableLengthForBase64 ~/ 4) * 3;
      var availableLength = lengthBeforeBase64;

      // At least 10 chars (random length).
      if (availableLength < 10) availableLength = 10;

      var splitData = split(utf8.encode(_value), availableLength);

      yield utf8.encode('$_name: $eol');
      for (var d in splitData) {
        yield b64prefix;
        yield utf8.encode(base64.encode(d));
        yield b64postfix;
      }
      return;
    }
    yield* _outValue(_value);
  }
}

class _IRHeaderAddress extends _IRHeader {
  Address _address;

  _IRHeaderAddress(String name, this._address) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outValue(_addressToString([_address]).first);
}

class _IRHeaderAddresses extends _IRHeader {
  Iterable<Address> _addresses;

  _IRHeaderAddresses(String name, this._addresses) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outValue(_addressToString(_addresses).join(', '));
}

class _IRHeaderContentType extends _IRHeader {
  String _boundary;
  _MultipartType _multipartType;

  _IRHeaderContentType(this._boundary, this._multipartType)
      : super('content-type');

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) {
    return _outValue(
        'multipart/${_describeEnum(_multipartType)};boundary="$_boundary"');
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
  var msgHeader = message.headers;

  // Add all custom headers which are not in [noCustom].
  msgHeader.forEach((name, value) {
    name = name.toLowerCase();
    if (noCustom.contains(name)) return;

    if (value is String && value.contains('@')) {
      headers.add(_IRHeaderAddress(name, Address(value)));
    } else if (value is String) {
      headers.add(_IRHeaderText(name, value));
    } else if (value is DateTime) {
      headers.add(_IRHeaderDate(name, value));
    } else if (value is Address) {
      headers.add(_IRHeaderAddress(name, value));
    } else if (value is Iterable<Address>) {
      headers.add(_IRHeaderAddresses(name, value));
    } else if (value is Iterable<String> &&
        value.every((s) => (s ?? '').contains('@'))) {
      headers.add(_IRHeaderAddresses(name, value.map((a) => Address(a))));
    } else {
      throw IRProblemException(
          Problem('INVALID_HEADER', 'Type of value for $name is invalid'));
    }
    headers.add(_IRHeaderText(name, value));
  });

  if (!msgHeader.containsKey('subject') && message.subject != null)
    headers.add(_IRHeaderText('subject', message.subject));

  if (!msgHeader.containsKey('from'))
    headers.add(_IRHeaderAddress('from', message.fromAsAddress));

  if (!msgHeader.containsKey('to')) {
    var tos = message.recipientsAsAddresses ?? [];
    if (tos.isNotEmpty) headers.add(_IRHeaderAddresses('to', tos));
  }

  if (!msgHeader.containsKey('cc')) {
    var ccs = message.ccsAsAddresses ?? [];
    if (ccs.isNotEmpty) headers.add(_IRHeaderAddresses('cc', ccs));
  }

  if (!msgHeader.containsKey('date'))
    headers.add(_IRHeaderDate('date', DateTime.now()));

  if (!msgHeader.containsKey('x-mailer'))
    headers.add(_IRHeaderText('x-mailer', 'Dart Mailer library 2'));

  headers.add(_IRHeaderText('mime-version', '1.0'));

  return headers;
}
