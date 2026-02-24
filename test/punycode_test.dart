import 'package:test/test.dart';
import 'package:mailer/src/core/address.dart';

void main() {
  group('Punycode Address', () {
    test('Encodes IDN domain correctly', () {
      final address = Address('test@münchen.de');
      expect(address.encodedAddress, equals('test@xn--mnchen-3ya.de'));
    });

    test('Does not encode ASCII domain', () {
      final address = Address('test@example.com');
      expect(address.encodedAddress, equals('test@example.com'));
    });

    test('Handles invalid address gracefully', () {
      final address = Address('invalid-address');
      expect(address.encodedAddress, equals('invalid-address'));
    });

    test('Handles multiple @ correctly', () {
      // The current implementation uses lastIndexOf('@')
      final address = Address('user@sub.domain@example.com');
      expect(address.encodedAddress, equals('user@sub.domain@example.com'));
    });
  });

  group('Punycode Edge Cases', () {
    test('IDN in subdomain', () {
      final address = Address('user@sub.münchen.de');
      expect(address.encodedAddress, equals('user@sub.xn--mnchen-3ya.de'));
    });

    test('Multiple IDN labels', () {
      final address = Address('user@münchen.münchen.de');
      expect(address.encodedAddress, equals('user@xn--mnchen-3ya.xn--mnchen-3ya.de'));
    });

    test('CJK domain (Japanese)', () {
      // 日本語.jp -> xn--wgv71a119e.jp
      final address = Address('user@日本語.jp');
      expect(address.encodedAddress, contains('xn--'));
      expect(address.encodedAddress, endsWith('.jp'));
    });

    test('CJK domain (Chinese)', () {
      // 中文.cn
      final address = Address('user@中文.cn');
      expect(address.encodedAddress, contains('xn--'));
      expect(address.encodedAddress, endsWith('.cn'));
    });

    test('Cyrillic domain', () {
      // россия.рф -> xn--h1alffa9f.xn--p1ai
      final address = Address('user@россия.рф');
      expect(address.encodedAddress, contains('xn--'));
    });

    test('Arabic domain', () {
      // مثال.مصر
      final address = Address('user@مثال.مصر');
      expect(address.encodedAddress, contains('xn--'));
    });

    test('Japanese Hiragana domain', () {
      // 例え.jp -> xn--r8jz45g.jp
      final address = Address('user@例え.jp');
      expect(address.encodedAddress, contains('xn--'));
      expect(address.encodedAddress, endsWith('.jp'));
    });

    test('Mixed ASCII and IDN labels', () {
      final address = Address('user@mail.münchen.example.com');
      expect(address.encodedAddress, equals('user@mail.xn--mnchen-3ya.example.com'));
    });

    test('Already punycode-encoded domain passes through', () {
      final address = Address('user@xn--mnchen-3ya.de');
      expect(address.encodedAddress, equals('user@xn--mnchen-3ya.de'));
    });

    test('IDN only in TLD', () {
      final address = Address('user@example.рф');
      expect(address.encodedAddress, contains('xn--'));
      expect(address.encodedAddress, startsWith('user@example.'));
    });

    test('Long IDN domain', () {
      // Test a longer IDN label
      final address = Address('user@bücherregal.de');
      expect(address.encodedAddress, contains('xn--'));
      expect(address.encodedAddress, endsWith('.de'));
    });
  });

  group('UTF-8 Normalization', () {
    test('NFC form (precomposed) encodes correctly', () {
      // "München" with ü as U+00FC (NFC - precomposed)
      final nfcAddress = Address('user@münchen.de');
      final nfcResult = nfcAddress.encodedAddress;
      expect(nfcResult, equals('user@xn--mnchen-3ya.de'));
    });

    test('NFD form (decomposed) encodes correctly', () {
      // "München" with ü as u + U+0308 (NFD - decomposed)
      // The u followed by combining diaeresis
      final nfdMuenchen = 'mu\u0308nchen'; // u + combining umlaut
      final nfdAddress = Address('user@$nfdMuenchen.de');
      final nfdResult = nfdAddress.encodedAddress;

      // Both forms should produce the same Punycode output
      // if the library normalizes to NFC internally
      expect(nfdResult, contains('xn--'));
      expect(nfdResult, endsWith('.de'));
    });

    test('NFC and NFD produce SAME Punycode with normalization', () {
      // NFC: ü = U+00FC
      final nfcDomain = 'mü.de';
      final nfcAddress = Address('user@$nfcDomain');

      // NFD: ü = u + U+0308
      final nfdDomain = 'mu\u0308.de';
      final nfdAddress = Address('user@$nfdDomain');

      // With NFC normalization, both forms produce the SAME Punycode output.
      // This is the correct IDNA behavior.
      expect(nfcAddress.encodedAddress, equals(nfdAddress.encodedAddress),
          reason: 'With NFC normalization, NFC and NFD should produce identical Punycode');

      // Both should be valid Punycode
      expect(nfcAddress.encodedAddress, contains('xn--'));
      expect(nfdAddress.encodedAddress, contains('xn--'));
    });

    test('NFC and NFD produce SAME Punycode for é', () {
      // NFC: é = U+00E9
      final nfcDomain = 'café.fr';
      final nfcAddress = Address('user@$nfcDomain');

      // NFD: é = e + U+0301 (combining acute accent)
      final nfdDomain = 'cafe\u0301.fr';
      final nfdAddress = Address('user@$nfdDomain');

      // With NFC normalization, both forms produce the SAME Punycode.
      expect(nfcAddress.encodedAddress, equals(nfdAddress.encodedAddress),
          reason: 'With NFC normalization, NFC and NFD should produce identical Punycode');
    });

    test('Complex combining characters', () {
      // Vietnamese: ệ = e + combining circumflex + combining dot below
      // Or as a precomposed character
      final complexChar = 'e\u0302\u0323'; // e + circumflex + dot below
      final domain = 'vi${complexChar}t.vn';
      final address = Address('user@$domain');

      // Should encode without crashing
      expect(address.encodedAddress, isNotEmpty);
      expect(() => address.encodedAddress, returnsNormally);
    });

    test('Zero-width characters in domain', () {
      // Zero-width joiner U+200D (should be handled or rejected)
      final domain = 'exam\u200Dple.com';
      final address = Address('user@$domain');

      // Should handle gracefully (either strip or encode)
      expect(() => address.encodedAddress, returnsNormally);
    });

    test('Right-to-left override characters', () {
      // U+202E Right-to-Left Override (potential security issue)
      final domain = 'exam\u202Eple.com';
      final address = Address('user@$domain');

      // Should handle gracefully
      expect(() => address.encodedAddress, returnsNormally);
    });
  });

  group('Edge Case: IDN in local-part', () {
    test('IDN local-part is not encoded (SMTP limitation)', () {
      // SMTP (RFC 5321) does not support UTF-8 in local-part without SMTPUTF8
      // The Address class only encodes the domain, not local-part
      final address = Address('münchen@example.com');
      // Local-part remains as-is; only domain is encoded
      expect(address.encodedAddress, equals('münchen@example.com'));
    });

    test('IDN in both local-part and domain', () {
      final address = Address('münchen@münchen.de');
      // Local-part unchanged, domain encoded
      expect(address.encodedAddress, equals('münchen@xn--mnchen-3ya.de'));
    });
  });

  group('Edge Case: Emoji domains', () {
    test('Single emoji in domain', () {
      // Many registrars don't allow emoji domains, but test encoding
      final address = Address('user@🔥.com');
      // Should attempt to encode (may produce xn-- or throw)
      expect(() => address.encodedAddress, returnsNormally);
    });

    test('Emoji in subdomain', () {
      final address = Address('user@mail.🔥.example.com');
      expect(() => address.encodedAddress, returnsNormally);
    });

    test('Mixed emoji and text', () {
      final address = Address('user@fire🔥domain.com');
      expect(() => address.encodedAddress, returnsNormally);
    });
  });
}
