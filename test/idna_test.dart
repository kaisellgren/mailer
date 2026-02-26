import 'package:test/test.dart';
import 'package:mailer/src/idna/idna.dart';

void main() {
  group('IDNA Encoder', () {
    group('Basic encoding', () {
      test('encodes German umlaut domain', () {
        expect(idnaEncode('münchen.de'), equals('xn--mnchen-3ya.de'));
      });

      test('returns ASCII domain unchanged', () {
        expect(idnaEncode('example.com'), equals('example.com'));
      });

      test('encodes Chinese domain', () {
        expect(idnaEncode('日本語.jp'), equals('xn--wgv71a119e.jp'));
      });

      test('returns empty string unchanged', () {
        expect(idnaEncode(''), equals(''));
      });
    });

    group('Case folding', () {
      test('converts uppercase to lowercase', () {
        expect(idnaEncode('EXAMPLE.COM'), equals('example.com'));
      });

      test('handles mixed case', () {
        expect(idnaEncode('ExAmPlE.CoM'), equals('example.com'));
      });

      test('converts uppercase IDN to lowercase', () {
        expect(idnaEncode('MÜNCHEN.DE'), equals('xn--mnchen-3ya.de'));
      });
    });

    group('NFC normalization', () {
      test('NFC form (precomposed) encodes correctly', () {
        // ü as U+00FC (precomposed)
        expect(idnaEncode('münchen.de'), equals('xn--mnchen-3ya.de'));
      });

      test('NFD form (decomposed) normalizes to same output', () {
        // ü as u + U+0308 (decomposed)
        final nfdMuenchen = 'mu\u0308nchen.de';
        expect(idnaEncode(nfdMuenchen), equals('xn--mnchen-3ya.de'));
      });

      test('NFC and NFD produce identical results', () {
        final nfc = 'mü.de'; // U+00FC
        final nfd = 'mu\u0308.de'; // u + U+0308
        expect(idnaEncode(nfc), equals(idnaEncode(nfd)));
      });

      test('é in NFC and NFD produce identical results', () {
        final nfc = 'café.fr'; // U+00E9
        final nfd = 'cafe\u0301.fr'; // e + U+0301
        expect(idnaEncode(nfc), equals(idnaEncode(nfd)));
      });
    });

    group('Multi-label domains', () {
      test('encodes single IDN subdomain', () {
        expect(idnaEncode('sub.münchen.de'), equals('sub.xn--mnchen-3ya.de'));
      });

      test('encodes multiple IDN labels', () {
        expect(idnaEncode('münchen.münchen.de'), equals('xn--mnchen-3ya.xn--mnchen-3ya.de'));
      });

      test('preserves mixed ASCII and IDN labels', () {
        expect(idnaEncode('mail.münchen.example.com'), equals('mail.xn--mnchen-3ya.example.com'));
      });

      test('handles deep subdomains', () {
        expect(idnaEncode('a.b.c.d.münchen.de'), equals('a.b.c.d.xn--mnchen-3ya.de'));
      });
    });

    group('Already encoded domains', () {
      test('does not double-encode Punycode', () {
        // Already encoded domain should pass through unchanged
        expect(idnaEncode('xn--mnchen-3ya.de'), equals('xn--mnchen-3ya.de'));
      });
    });

    group('Error handling', () {
      test('throws on label exceeding max length', () {
        final longLabel = 'a' * 64;
        expect(() => idnaEncode('$longLabel.com'), throwsA(isA<IdnaException>()));
      });
    });
  });

  group('IDNA Decoder', () {
    test('decodes Punycode domain', () {
      expect(idnaDecode('xn--mnchen-3ya.de'), equals('münchen.de'));
    });

    test('returns ASCII domain unchanged', () {
      expect(idnaDecode('example.com'), equals('example.com'));
    });

    test('decodes multiple Punycode labels', () {
      expect(idnaDecode('xn--mnchen-3ya.xn--mnchen-3ya.de'), equals('münchen.münchen.de'));
    });

    test('returns empty string unchanged', () {
      expect(idnaDecode(''), equals(''));
    });
  });

  group('Utility functions', () {
    test('containsNonAscii detects non-ASCII', () {
      expect(containsNonAscii('münchen'), isTrue);
      expect(containsNonAscii('example'), isFalse);
      expect(containsNonAscii('日本語'), isTrue);
    });

    test('isPunycodeEncoded detects xn-- prefix', () {
      expect(isPunycodeEncoded('xn--mnchen-3ya.de'), isTrue);
      expect(isPunycodeEncoded('example.com'), isFalse);
      expect(isPunycodeEncoded('sub.xn--mnchen-3ya.de'), isTrue);
    });
  });
}
