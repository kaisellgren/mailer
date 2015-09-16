// Tests for the [Address] class.
//
// Using the test framework documented at <https://pub.dartlang.org/packages/test>
//----------------------------------------------------------------

import 'package:test/test.dart';
import 'package:mailer/mailer.dart';

void main() {
  //var testAddr = new Address("foo@bar");

  //----------------
  // Can parse valid addresses

  group("Valid address:", () {
    var str1 = "user@example.com";
    test(str1, () {
      var addr = new Address(str1);
      expect(addr.displayName, equals(null));
      expect(addr.localPart, equals("user"));
      expect(addr.domain, equals("example.com"));
      expect(addr.route, equals(null));
    });

    var str2 = "<user@example.com>";
    test(str2, () {
      var addr = new Address(str2);
      expect(addr.displayName, isNull);
      expect(addr.localPart, equals("user"));
      expect(addr.domain, equals("example.com"));
      expect(addr.route, equals(null));
    });

    var str3 = "foobar<user@example.com>";
    test(str3, () {
      var addr = new Address(str3);
      expect(addr.displayName, equals("foobar"));
      expect(addr.localPart, equals("user"));
      expect(addr.domain, equals("example.com"));
      expect(addr.route, equals(null));
    });

    var str4 = "\"Foo Bar\" <@proxy.example.com:user@example.com>";
    test(str4, () {
      var addr = new Address(str4);
      expect(addr.displayName, equals("Foo Bar"));
      expect(addr.localPart, equals("user"));
      expect(addr.domain, equals("example.com"));

      expect(addr.route, isNotNull);
      expect(addr.route.length, equals(1));
      expect(addr.route[0], equals("proxy.example.com"));
    });

    var str5 = "<@p1.example.com,@p2.example.com:user@example.com>";
    test(str5, () {
      var addr = new Address(str5);
      expect(addr.displayName, isNull);
      expect(addr.localPart, equals("user"));
      expect(addr.domain, equals("example.com"));

      expect(addr.route, isNotNull);
      expect(addr.route.length, equals(2));
      expect(addr.route[0], equals("p1.example.com"));
      expect(addr.route[1], equals("p2.example.com"));
    });

    // Example from RFC 822
    var strRFC822a = "\":sysmail\"@  Some-Group. Some-Org";
    test(strRFC822a, () {
      var addr = new Address(strRFC822a);
      expect(addr.displayName, equals(null));
      expect(addr.localPart, equals(":sysmail"));
      expect(addr.domain, equals("Some-Group.Some-Org"));
      expect(addr.route, equals(null));
      expect(addr.toString(), equals("\":sysmail\"@Some-Group.Some-Org"));
    });

    // Example from RFC 822

    var strRFC822b = "Muhammed.(I am  the greatest) Ali @(the)Vegas.WBA";
    test(strRFC822b, () {
      var addr = new Address(strRFC822b);
      expect(addr.displayName, isNull);
      expect(addr.localPart, equals("Muhammed.Ali"));
      expect(addr.domain, equals("Vegas.WBA"));
      expect(addr.route, equals(null));
    });

    // Other valid addresses

    for (var str in [
      '<j.smith@example.com>',
      'John Smith <j.smith@example.com>',
      '"John Smith" <j.smith@example.com>',
      "a@b",
      "a-b+c@example.com",
      '"much.more unusual"@example.com',
      '"very.unusual.@.unusual.com"@example.com',
      '"very.(),:;<>[]\\".VERY.\\"very@\\\\ \\"very\\".unusual"@strange.example.com',
      "#!\$%&'*+-/=?^_`{}|~@example.org",
      '"()<>[]:,;@\\\\\\"!#\$%&\\\'*+-/=?^_`{}| ~.a"@example.org',
      '" "@example.org',
      "üñîçøðé@example.com",
      "üñîçøðé@üñîçøðé.com",
      "a.b.c.d.e@example.com",
      "a@b.c.d.example.com",
      "group:;",
      "group:a@b;",
      "group:a@b,c@d;"
    ]) {
      test(str, () {
        expect(Address.sanitize(str), isNotEmpty);
      });
    }
  });

  //----------------
  // Can reject invalid addresses

  group("Invalid address:", () {
    for (var badAddr in [
      null,
      "",
      "   ",
      "a",
      "a@",
      "@b",
      "a@b@c",
      ".a@b",
      "a.@b",
      "a..b@c",
      "a@.b",
      "a@b.",
      "a@b..c",
      'just"not"right@example.com',
      "unquoted space@example.com",
      'bareQuote"notAllowed@example.com',
      "escapedUnquoted\ space@example.com",
      'escapedBareQuote\\"notAllowed@example.com',
      "foo a@missingBothAngleBrackets",
      "foo a@missingLeftAngleBracket>",
      "foo<a@missingRightAngleBracket",
      // bad routes
      "route<@:a@b>",
      "route<:a@b>",
      "route<,@foo:a@b>",
      "route<@foo,,@bar:a@b>",
      "route<@foo,:a@b>",
      "route<@foo @bar:a@b>",
      // bad groups
      "group:",
      "group:a@b",
      "group:,a@b;",
      "group:a@b,,c@d;",
      "group:a@b,;",
      "group:a@b c@d;",
      // extra text at end
      "a@b extra",
      "foo<a@b>extra",
      "group:a@b;extra"
    ]) {
      test(badAddr, () {
        expect(() {
          try {
            new Address(badAddr);
          } catch (e) {
            //print("           $e"); // uncomment to see exception messages
            rethrow;
          }
        }, throwsA(new isInstanceOf<AddressInvalid>()));
      });
    }
  });

  group("Sanitize", () {
    var values = [
    [ "a@b", "a@b"],
    [ "a.b.c@d", "a.b.c@d"],
    [ " foo.bar @ baz.example.com ", "foo.bar@baz.example.com"],
    [ "foobar < a@b >", "foobar<a@b>"],
    [ 'foo"bar"baz < a@b >', '"foo bar baz"<a@b>'],
    ];

    for (var value in values) {
      var input = value[0];
      var output = value[1];

      test(input, () {
        expect(Address.sanitize(input), equals(output));
      });
    }
  });
}
