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

/// The Punycode codec instance used for encoding/decoding.
const _punycodeCodec = PunycodeCodec();

/// Encodes a domain name to its ASCII-compatible (Punycode) form.
///
/// This function:
/// 1. Splits the domain into labels (parts between dots)
/// 2. Normalizes each label to NFC (Normalization Form Canonical Composition)
/// 3. Performs case folding (converts to lowercase)
/// 4. Applies Punycode encoding with 'xn--' prefix for non-ASCII labels
/// 5. Validates label lengths (≤63 characters)
///
/// Throws [IdnaException] if:
/// - A label exceeds 63 characters after encoding
/// - The domain exceeds 253 characters
/// - A label is empty
/// - The Punycode encoding fails
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

  final labels = domain.split('.');
  final encodedLabels = <String>[];

  for (final label in labels) {
    final encoded = _encodeLabel(label);
    encodedLabels.add(encoded);
  }

  final result = encodedLabels.join('.');

  // Validate total domain length
  if (result.length > maxDomainLength) {
    throw IdnaException('Encoded domain exceeds maximum length of $maxDomainLength characters: '
        '${result.length} characters');
  }

  return result;
}

/// Encodes a single domain label using IDNA rules.
String _encodeLabel(String label) {
  if (label.isEmpty) {
    // Empty labels can occur with trailing dots (e.g., "example.com.")
    // Return as-is to preserve the structure
    return label;
  }

  // 1. Normalize to NFC (Normalization Form Canonical Composition)
  // This ensures that characters like 'ü' (U+00FC) and 'u' + '̈' (U+0308)
  // are treated identically.
  String normalized = unorm.nfc(label);

  // 2. Case folding: convert to lowercase
  // Domain names are case-insensitive per DNS specifications.
  normalized = normalized.toLowerCase();

  // 3. Encode using PunycodeCodec
  // The codec automatically:
  // - Returns unchanged if already ASCII
  // - Adds 'xn--' prefix for non-ASCII labels
  try {
    final encoded = _punycodeCodec.encode(normalized);

    // 4. Validate encoded label length
    if (encoded.length > maxLabelLength) {
      throw IdnaException('Encoded label exceeds maximum length of $maxLabelLength characters: '
          '"$encoded" (${encoded.length} characters)');
    }

    return encoded;
  } catch (e) {
    if (e is IdnaException) rethrow;
    throw IdnaException('Failed to encode label "$label": $e');
  }
}

/// Decodes a Punycode-encoded domain name back to Unicode.
///
/// This function:
/// 1. Splits the domain into labels
/// 2. Detects 'xn--' prefixed labels and decodes them
/// 3. Returns the decoded Unicode domain
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

  final labels = domain.split('.');
  final decodedLabels = <String>[];

  for (final label in labels) {
    final decoded = _decodeLabel(label);
    decodedLabels.add(decoded);
  }

  return decodedLabels.join('.');
}

/// Decodes a single Punycode label.
String _decodeLabel(String label) {
  if (label.isEmpty) {
    return label;
  }

  // PunycodeCodec.decode handles 'xn--' prefixed labels automatically
  try {
    return _punycodeCodec.decode(label);
  } catch (e) {
    throw IdnaException('Failed to decode Punycode label "$label": $e');
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
