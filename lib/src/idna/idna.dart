/// IDNA (Internationalized Domain Names in Applications) encoding.
///
/// This module provides proper IDNA encoding with:
/// - NFC Unicode normalization
/// - Case folding (lowercase)
/// - Punycode encoding with ACE prefix (xn--)
/// - Label length validation (≤63 characters)
///
/// This implementation follows IDNA2008 conventions and can be extracted
/// into a standalone library if needed.
library;

import 'package:punycoder/punycoder.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// Maximum length of a single DNS label (before or after encoding).
const int maxLabelLength = 63;

/// Maximum length of a complete domain name.
const int maxDomainLength = 253;

/// The ACE (ASCII Compatible Encoding) prefix for Punycode labels.
const String acePrefix = 'xn--';

/// Exception thrown when IDNA encoding fails.
class IdnaException implements Exception {
  /// A description of the error.
  final String message;

  /// Creates an [IdnaException] with the given [message].
  const IdnaException(this.message);

  @override
  String toString() => 'IdnaException: $message';
}

/// Encodes a domain name to its ASCII-compatible (Punycode) form.
///
/// This function:
/// 1. Normalizes the domain to NFC
/// 2. Applies IDNA encoding using [domainToAscii]
///
/// Throws [IdnaException] if encoding or validation fails.
///
/// Example:
/// ```dart
/// idnaEncode('München.de'); // Returns 'xn--mnchen-3ya.de'
/// idnaEncode('日本語.jp');   // Returns 'xn--wgv71a119e.jp'
/// idnaEncode('example.com'); // Returns 'example.com' (no change)
/// ```
String idnaEncode(String domain) {
  if (domain.isEmpty) {
    return domain;
  }

  // Normalize to NFC (Normalization Form Canonical Composition)
  // punycoder expects input to be normalized.
  final normalized = unorm.nfc(domain);

  try {
    // Use domainToAscii which handles splitting, lowercase, prefix and validation
    return domainToAscii(normalized);
  } on FormatException catch (e) {
    throw IdnaException(e.message);
  }
}

/// Decodes a Punycode-encoded domain name back to Unicode.
///
/// This function uses [domainToUnicode] to handle 'xn--' prefixed labels.
///
/// Throws [IdnaException] if Punycode decoding fails.
///
/// Example:
/// ```dart
/// idnaDecode('xn--mnchen-3ya.de'); // Returns 'münchen.de'
/// ```
String idnaDecode(String domain) {
  if (domain.isEmpty) {
    return domain;
  }

  try {
    return domainToUnicode(domain);
  } on FormatException catch (e) {
    throw IdnaException(e.message);
  }
}

/// Checks if a domain contains any non-ASCII characters.
///
/// Returns `true` if the domain contains characters with code points > U+007F.
bool containsNonAscii(String domain) {
  return domain.codeUnits.any((unit) => unit > 0x7F);
}

/// Checks if a domain is already Punycode-encoded.
///
/// Returns `true` if any label starts with 'xn--'.
bool isPunycodeEncoded(String domain) {
  return domain.split('.').any((label) => label.toLowerCase().startsWith(acePrefix));
}
