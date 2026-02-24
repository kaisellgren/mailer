import 'address.dart';

abstract class AddressValidator {
  bool validate(Address address);
}

/// A validator that permits any non-empty address.
class PermissiveAddressValidator implements AddressValidator {
  const PermissiveAddressValidator();

  @override
  bool validate(Address address) {
    return address.mailAddress.isNotEmpty;
  }
}

/// A validator that checks for simple email format (contains @).
class SimpleAddressValidator implements AddressValidator {
  const SimpleAddressValidator();

  @override
  bool validate(Address address) {
    return address.mailAddress.contains('@') && address.mailAddress.length > 2;
  }
}

/// A validator with sensible real-world restrictions for input validation.
///
/// This validator is stricter than RFC 5322 but more practical for actual
/// email delivery. Many mail providers (including Gmail) reject addresses
/// that use rarely-supported RFC features.
///
/// **Recommended for:** Validating user input in forms before accepting
/// email addresses.
///
/// **Allowed:**
/// - Standard dot-atom local-parts (e.g., `user.name`, `user+tag`)
/// - Domain names (e.g., `example.com`, `sub.example.com`)
/// - All atext special characters: `!#$%&'*+-/=?^_\`{|}~`
///
/// **Rejected:**
/// - Domain literals / IP addresses (e.g., `user@[192.168.1.1]`)
/// - Quoted strings in local-part (e.g., `"john doe"@example.com`)
/// - Comments (rarely supported)
/// - Empty local-parts or domains
/// - Consecutive dots or leading/trailing dots
/// - Domains without a dot (e.g., `user@localhost`)
///
/// Use [StrictAddressValidator] if you need full RFC 5322 compliance,
/// or [PermissiveAddressValidator] if you want to accept anything.
class PracticalAddressValidator implements AddressValidator {
  const PracticalAddressValidator();

  @override
  bool validate(Address address) {
    try {
      if (address.mailAddress.isEmpty) return false;
      _AddressParser(
        address.mailAddress,
        allowQuotedString: false,
        allowDomainLiteral: false,
        requireDomainDot: true,
      ).validate();
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// A validator that tries to be compliant with RFC 5322.
///
/// This validator is based on the legacy `Address` parser from earlier versions
/// of this library.
class StrictAddressValidator implements AddressValidator {
  const StrictAddressValidator();

  @override
  bool validate(Address address) {
    try {
      if (address.mailAddress.isEmpty) return false;
      _AddressParser(
        address.mailAddress,
        allowQuotedString: true,
        allowDomainLiteral: true,
        requireDomainDot: false,
        allowComments: true,
      ).validate();
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _AddressParser {
  final String text;
  final bool allowQuotedString;
  final bool allowDomainLiteral;
  final bool requireDomainDot;
  final bool allowComments;
  int _index = 0;

  _AddressParser(
    this.text, {
    this.allowQuotedString = false,
    this.allowDomainLiteral = false,
    this.requireDomainDot = false,
    this.allowComments = false,
  });

  void validate() {
    _parseAddrSpec();
    if (_index < text.length) {
      throw FormatException('Unexpected characters at end of address');
    }
  }

  void _parseAddrSpec() {
    _parseLocalPart();
    _expect('@');
    _skipCFWS();
    final domainStart = _index;
    _parseDomain();

    if (requireDomainDot) {
      if (!text.substring(domainStart, _index).contains('.')) {
        throw FormatException('Domain must contain at least one dot');
      }
    }
  }

  void _parseLocalPart() {
    _skipCFWS();
    if (_peek() == '"') {
      if (allowQuotedString) {
        _parseQuotedString();
        _skipCFWS();
      } else {
        throw FormatException('Quoted strings not allowed in local-part');
      }
    } else {
      if (_peek() == '(') {
        throw FormatException('Comments not allowed');
      }
      _parseDotAtom();
    }
  }

  void _parseDomain() {
    _skipCFWS();
    if (_peek() == '[') {
      if (allowDomainLiteral) {
        _parseDomainLiteral();
        _skipCFWS();
      } else {
        throw FormatException('Domain literals (IP addresses) not allowed');
      }
    } else {
      if (_peek() == '(') {
        throw FormatException('Comments not allowed');
      }
      _parseDotAtom();
    }
  }

  void _parseDotAtom() {
    _skipCFWS();
    if (!_isAtext(_peek())) {
      throw FormatException('Expected atom at position $_index');
    }
    _parseAtom();
    _skipCFWS();

    while (_peek() == '.') {
      _advance();
      _skipCFWS();
      if (!_isAtext(_peek())) {
        throw FormatException('Invalid dot position at $_index');
      }
      _parseAtom();
      _skipCFWS();
    }
  }

  void _parseAtom() {
    if (!_isAtext(_peek())) {
      throw FormatException('Expected atom at position $_index');
    }
    while (_isAtext(_peek())) {
      _advance();
    }
  }

  void _parseQuotedString() {
    _expect('"');
    while (_index < text.length) {
      final char = _peek();
      if (char == '"') {
        _advance();
        return;
      } else if (char == '\\') {
        _advance();
        if (_index >= text.length) throw FormatException('Unterminated escape');
        _advance();
      } else {
        _advance();
      }
    }
    throw FormatException('Unterminated quoted string');
  }

  void _parseDomainLiteral() {
    _expect('[');
    while (_index < text.length) {
      final char = _peek();
      if (char == ']') {
        _advance();
        return;
      }
      _advance();
    }
    throw FormatException('Unterminated domain literal');
  }

  void _skipCFWS() {
    if (!allowComments) return;
    while (true) {
      final char = _peek();
      if (char == ' ' || char == '\t' || char == '\r' || char == '\n') {
        _advance();
      } else if (char == '(') {
        _parseComment();
      } else {
        break;
      }
    }
  }

  void _parseComment() {
    _expect('(');
    int depth = 1;
    while (_index < text.length) {
      final char = _peek();
      if (char == '(') {
        depth++;
        _advance();
      } else if (char == ')') {
        depth--;
        _advance();
        if (depth == 0) return;
      } else if (char == '\\') {
        _advance();
        if (_index < text.length) _advance();
      } else {
        _advance();
      }
    }
    throw FormatException('Unterminated comment');
  }

  void _expect(String char) {
    if (_peek() != char) {
      throw FormatException('Expected "$char" at position $_index');
    }
    _advance();
  }

  String _peek() {
    if (_index >= text.length) return '';
    return text[_index];
  }

  void _advance() {
    _index++;
  }

  bool _isAtext(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5a) || // A-Z
        (code >= 0x61 && code <= 0x7a) || // a-z
        (code >= 0x30 && code <= 0x39) || // 0-9
        "!#\$%&'*+-/=?^_`{|}~".contains(char);
  }
}
