part of 'internal_representation.dart';

abstract class _IRHeader extends _IROutput {
  final String _name;

  static final List<int> _b64prefix = convert.utf8.encode(' =?utf-8?B?');
  static final List<int> _b64postfix = convert.utf8.encode('?=$eol');
  static final int _b64Length = _b64prefix.length + _b64postfix.length;

  Stream<List<int>> _outValue(String value) =>
      new Stream.fromIterable([_name, ': ', value, eol].map(convert.utf8.encode));

  // Outputs value encoded as base64.
  // Every chunk starts with ' ' and ends with eol.
  // Call _outValueB64 after an eol.
  Stream<List<int>> _outValueB64(String value) async* {
    // Encode with base64.
    var availableLengthForBase64 = maxEncodedLength - _b64Length;

    // Length after base64: ceil(n / 3) * 4
    var lengthBeforeBase64 = (availableLengthForBase64 ~/ 4) * 3;
    var availableLength = lengthBeforeBase64;

    // At least 10 chars (random length).
    if (availableLength < 10) availableLength = 10;

    var splitData = split(convert.utf8.encode(value), availableLength);

    yield convert.utf8.encode('$_name: $eol');
    for (var d in splitData) {
      yield _b64prefix;
      yield convert.utf8.encode(convert.base64.encode(d));
      yield _b64postfix;
    }
  }

  /*
  Stream<List<int>> _outValue8(List<int> value) => Stream.fromIterable(
      [_name, ': '].map(utf8.encode).followedBy([value, _eol8]));
      */

  _IRHeader(this._name);
}

class _IRHeaderText extends _IRHeader {
  String _value;

  // RegExp created using:
  // https://mothereff.in/regexpu
  // `string.match(/^[^\p{Cc}\p{Cf}\p{Zl}\p{Zp}]*$/u);`
  // as suggested by: https://stackoverflow.com/questions/12052825/regular-expression-for-all-printable-characters-in-javascript
  final _isPrintableRegExp = new RegExp(r'^(?:[ -~\xA0-\xAC\xAE-\u05FF\u0606-\u061B\u061D-\u06DC\u06DE-\u070E\u0710-\u08E1\u08E3-\u180D\u180F-\u200A\u2010-\u2027\u202F-\u205F\u2065\u2070-\uD7FF\uE000-\uFEFE\uFF00-\uFFF8\uFFFC-\uFFFF]|[\uD800-\uD803\uD805-\uD82E\uD830-\uD833\uD835-\uDB3F\uDB41-\uDBFF][\uDC00-\uDFFF]|\uD804[\uDC00-\uDCBC\uDCBE-\uDCCC\uDCCE-\uDFFF]|\uD82F[\uDC00-\uDC9F\uDCA4-\uDFFF]|\uD834[\uDC00-\uDD72\uDD7B-\uDFFF]|\uDB40[\uDC00\uDC02-\uDC1F\uDC80-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])*$');

  _IRHeaderText(String name, this._value) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) {
    bool utf8Allowed = irMetaInformation.capabilities.smtpUtf8;

    if (_value.length > maxLineLength ||
        !_isPrintableRegExp.hasMatch(_value) ||
        // Make sure that text which looks like an encoded text is encoded.
        _value.contains('=?') ||
        (!utf8Allowed && _value.contains(new RegExp(r'[^\x20-\x7E]')))) {
      return _outValueB64(_value);
    }
    return _outValue(_value);
  }
}

Iterable<String> _addressToString(Iterable<Address> addresses) {
  if (addresses == null) return [];
  return addresses.map((a) {
    var fromName = a.name ?? '';
    // ToDo base64 fromName (add _IRMetaInformation as argument)
    return '$fromName <${a.mailAddress}>';
  });
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
      new DateFormat('EEE, dd MMM yyyy HH:mm:ss +0000');

  _IRHeaderDate(String name, this._dateTime) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outValue(_dateFormat.format(_dateTime.toUtc()));
}

Iterable<_IRHeader> _buildHeaders(Message message) {
  const noCustom = const ['content-type', 'mime-version'];

  final headers = <_IRHeader>[];
  var msgHeader = message.headers;

  // Add all custom headers which are not in [noCustom].
  msgHeader.forEach((name, value) {
    name = name.toLowerCase();
    if (noCustom.contains(name)) return;

    if (value is String && value.contains('@')) {
      headers.add(new _IRHeaderAddress(name, new Address(value)));
    } else if (value is String) {
      headers.add(new _IRHeaderText(name, value));
    } else if (value is DateTime) {
      headers.add(new _IRHeaderDate(name, value));
    } else if (value is Address) {
      headers.add(new _IRHeaderAddress(name, value));
    } else if (value is Iterable<Address>) {
      headers.add(new _IRHeaderAddresses(name, value));
    } else if (value is Iterable<String> &&
        value.every((s) => (s ?? '').contains('@'))) {
      headers.add(new _IRHeaderAddresses(name, value.map((a) => new Address(a))));
    } else {
      throw new IRProblemException(
          new Problem('INVALID_HEADER', 'Type of value for $name is invalid'));
    }
  });

  if (!msgHeader.containsKey('subject') && message.subject != null)
    headers.add(new _IRHeaderText('subject', message.subject));

  if (!msgHeader.containsKey('from'))
    headers.add(new _IRHeaderAddress('from', message.fromAsAddress));

  if (!msgHeader.containsKey('to')) {
    var tos = message.recipientsAsAddresses ?? [];
    if (tos.isNotEmpty) headers.add(new _IRHeaderAddresses('to', tos));
  }

  if (!msgHeader.containsKey('cc')) {
    var ccs = message.ccsAsAddresses ?? [];
    if (ccs.isNotEmpty) headers.add(new _IRHeaderAddresses('cc', ccs));
  }

  if (!msgHeader.containsKey('date'))
    headers.add(new _IRHeaderDate('date', new DateTime.now()));

  if (!msgHeader.containsKey('x-mailer'))
    headers.add(new _IRHeaderText('x-mailer', 'Dart Mailer library 2'));

  headers.add(new _IRHeaderText('mime-version', '1.0'));

  return headers;
}
