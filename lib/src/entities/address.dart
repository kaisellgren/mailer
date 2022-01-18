final _quotableNameRegExp = RegExp(r'[",]');

class Address {
  final String? name;
  final String mailAddress;

  const Address(this.mailAddress, [this.name]);

  /// The name used to output to SMTP server.
  /// Implementation can override it to pre-process the name before sending.
  /// For example, providing a default name for certain address, or quoting it.
  String? get sanitizedName {
    if (name == null) return null;

    // Quote the name if it contains a comma or a quote.
    if (name!.contains(_quotableNameRegExp)) {
      return '"${name!.replaceAll('"', r'\"')}"';
    }

    return name;
  }

  /// The address used to output to SMTP server.
  /// Implementation can override it to pre-process the address before sending
  String get sanitizedAddress => mailAddress;

  @override
  String toString() => "${name ?? ''} <$mailAddress>";
}

final _commaCodeUnit = ','.codeUnitAt(0);
final _quoteCodeUnit = '"'.codeUnitAt(0);
final _openAngleBracket = '<'.codeUnitAt(0);
final _closeAngleBracket = '>'.codeUnitAt(0);
final _backslashCodeUnit = r'\'.codeUnitAt(0);

/// Parse a comma-separated list of rfc5322 3.4 mailboxes to a `List<Address>`.
/// Does not handle rfc5322 comments.
List<Address> parseMailboxes(String addresses) {
  var result = <Address>[];
  var inQuote = false;
  var inAngleBrackets = false;
  var nameOrEmail = <int>[];
  var email = <int>[];
  var name = <int>[];

  void addAddress() {
    if (nameOrEmail.isNotEmpty) {
      if (email.isEmpty) {
        email.addAll(nameOrEmail);
      } else if (name.isEmpty) {
        name.addAll(nameOrEmail);
      }
    }

    if (email.isNotEmpty) {
      result.add(Address(String.fromCharCodes(email).trim(),
          String.fromCharCodes(name).trim()));
    }

    email.clear();
    name.clear();
    nameOrEmail.clear();
    inAngleBrackets = false;
    inQuote = false;
  }

  var codeUnits = addresses.codeUnits;
  for (var p = 0; p < codeUnits.length; p++) {
    var c = codeUnits[p];
    if (inQuote) {
      if (c == _quoteCodeUnit) {
        inQuote = false;
      } else if (c == _backslashCodeUnit) {
        // Handle \ escape - \" inside of quotes
        ++p;
        if (p < codeUnits.length) {
          name.add(codeUnits[p]);
        }
      } else {
        name.add(c);
      }
    } else if (inAngleBrackets) {
      if (c == _closeAngleBracket) {
        inAngleBrackets = false;
      } else {
        email.add(c);
      }
    } else if (c == _commaCodeUnit) {
      addAddress();
    } else if (c == _quoteCodeUnit) {
      inQuote = true;
    } else if (c == _openAngleBracket) {
      inAngleBrackets = true;
    } else {
      nameOrEmail.add(c);
    }
  }

  // Catch last one, if any.
  addAddress();

  return result;
}
