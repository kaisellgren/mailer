part of 'internal_representation.dart';

abstract class _IRHeader extends _IROutput {
  final String _name;

  static final _b64prefix = convert.utf8.encode('=?utf-8?B?'),
      _b64postfix = convert.utf8.encode('?='),
      _$eol = convert.utf8.encode(eol),
      _$eolSpace = convert.utf8.encode('$eol '),
      _$spaceLt = convert.utf8.encode(' <'),
      _$gt = convert.utf8.encode('>'),
      _$commaSpace = convert.utf8.encode(', '),
      _$colonSpace = convert.utf8.encode(': ');
  static final int _b64Length = _b64prefix.length + _b64postfix.length;

  Stream<List<int>> _outValue(String? value) async* {
    yield convert.utf8.encode(_name);
    yield _$colonSpace;
    if (value != null) yield convert.utf8.encode(value);
    yield _$eol;
  }

  Stream<List<int>> _outValueWithParms(
      String value, _IRMetaInformation irMetaInformation,
      [Map<String, String>? parms]) async* {
    yield convert.utf8.encode(_name);
    yield _$colonSpace;
    if (_IRHeader._shallB64(value, irMetaInformation)) {
      yield* _outB64(value);
    } else {
      yield convert.utf8.encode(value);
    }
    if (parms != null) {
      for (var parm in (parms.entries)) {
        yield convert.utf8.encode('; ${parm.key}="');
        if (_IRHeader._shallB64(parm.value, irMetaInformation)) {
          yield* _outB64(parm.value);
        } else {
          yield convert.utf8.encode(parm.value);
        }
        yield convert.utf8.encode('"');
      }
    }
    yield _$eol;
  }

  /// Outputs the given [addresses].
  Stream<List<int>> _outAddressesValue(Iterable<Address> addresses,
      _IRMetaInformation irMetaInformation) async* {
    yield convert.utf8.encode(_name);
    yield _$colonSpace;

    var len = 2, //2 = _$commaSpace
        second = false;
    for (final address in addresses) {
      final name = address.sanitizedName, maddr = address.sanitizedAddress;
      var adrlen = maddr.length;
      if (name != null) {
        adrlen += name.length + 3;
      } //not accurate but good enough

      if (second) {
        yield _$commaSpace;

        if (len + adrlen > maxEncodedLength) {
          len = 2;
          yield _$eolSpace;
        }
      } else {
        second = true;
      }

      if (name == null) {
        yield convert.utf8.encode(maddr);
      } else {
        if (_shallB64(name, irMetaInformation)) {
          yield* _outB64(name);
        } else {
          yield convert.utf8.encode(name);
        }

        yield _$spaceLt;
        yield convert.utf8.encode(maddr);
        yield _$gt;
      }

      len += adrlen;
    }

    yield _$eol;
  }

  // Outputs the given [value] encoded as base64.
  static Stream<List<int>> _outB64(String value) async* {
    // Encode with base64.
    var availableLengthForBase64 = maxEncodedLength - _b64Length;

    // Length after base64: ceil(n / 3) * 4
    var lengthBeforeBase64 = (availableLengthForBase64 ~/ 4) * 3;
    var availableLength = lengthBeforeBase64;

    // At least 10 chars (random length).
    if (availableLength < 10) availableLength = 10;

    var second = false;
    for (var d in split(convert.utf8.encode(value), availableLength)) {
      if (second) {
        yield _$eolSpace;
      } else {
        second = true;
      }

      yield _b64prefix;
      yield convert.utf8.encode(convert.base64.encode(d));
      yield _b64postfix;
    }
  }

  static bool _shallB64(String value, _IRMetaInformation irMetaInformation) {
    // If we have a maxLineLength is it the length of utf8 characters or
    // the length of utf8 bytes?
    // Just to be safe we'll count the bytes.
    var byteLength = convert.utf8.encode(value).length;
    return (byteLength > maxLineLength ||
        !isPrintableRegExp.hasMatch(value) ||
        // Make sure that text which looks like an encoded text is encoded.
        value.contains('=?') ||
        (!irMetaInformation.capabilities.smtpUtf8 &&
            value.contains(RegExp(r'[^\x20-\x7E]'))));
  }

  /*
  Stream<List<int>> _outValue8(List<int> value) => Stream.fromIterable(
      [_name, ': '].map(utf8.encode).followedBy([value, _eol8]));
      */

  _IRHeader(this._name);
}

class _IRHeaderText extends _IRHeader {
  final String _value;
  final Map<String, String>? _parms;

  _IRHeaderText(String name, this._value, [this._parms]) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outValueWithParms(_value, irMetaInformation, _parms);
}

class _IRHeaderAddress extends _IRHeader {
  final Address _address;

  _IRHeaderAddress(String name, this._address) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outAddressesValue([_address], irMetaInformation);
}

class _IRHeaderAddresses extends _IRHeader {
  final Iterable<Address> _addresses;

  _IRHeaderAddresses(String name, this._addresses) : super(name);

  @override
  Stream<List<int>> out(_IRMetaInformation irMetaInformation) =>
      _outAddressesValue(_addresses, irMetaInformation);
}

class _IRHeaderContentType extends _IRHeader {
  final String _boundary;
  final _MultipartType _multipartType;

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
      DateFormat('EEE, dd MMM yyyy HH:mm:ss +0000', 'en_US');

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
        value.every((s) => (s).contains('@'))) {
      headers.add(_IRHeaderAddresses(name, value.map((a) => Address(a))));
    } else {
      throw InvalidHeaderException('Type of value for $name is invalid');
    }
  });

  if (!msgHeader.containsKey('subject') && message.subject != null) {
    headers.add(_IRHeaderText('subject', message.subject!));
  }

  if (!msgHeader.containsKey('from')) {
    headers.add(_IRHeaderAddress('from', message.fromAsAddress));
  }

  if (!msgHeader.containsKey('to')) {
    var tos = message.recipientsAsAddresses;
    if (tos.isNotEmpty) headers.add(_IRHeaderAddresses('to', tos));
  }

  if (!msgHeader.containsKey('cc')) {
    var ccs = message.ccsAsAddresses;
    if (ccs.isNotEmpty) headers.add(_IRHeaderAddresses('cc', ccs));
  }

  if (!msgHeader.containsKey('date')) {
    headers.add(_IRHeaderDate('date', DateTime.now()));
  }

  if (!msgHeader.containsKey('x-mailer')) {
    headers.add(_IRHeaderText('x-mailer', 'Dart Mailer library'));
  }

  headers.add(_IRHeaderText('mime-version', '1.0'));

  return headers;
}
