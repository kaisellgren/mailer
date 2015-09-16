// Address

part of mailer;

//================================================================
// Exception classes

/// Base exception class raised by methods in the [Address] class.
///
class AddressException implements Exception {
  String message;
  AddressException(this.message);

  String toString() => message;
}

/// Exception thrown by the [Address] constructors.
///
class AddressInvalid extends AddressException {
  AddressInvalid(String msg) : super("Address invalid: $msg");
}

/// Exception thrown when accessing mailbox properties on a group [Address].
///
class AddressNotMailbox extends AddressException {
  AddressNotMailbox() : super("Not a mailbox address");
}

/// Exception thrown when accessing group properties on a mailbox [Address]
///
class AddressNotGroup extends AddressException {
  AddressNotGroup() : super("Not a group address");
}

//================================================================

/// An RFC #822 address, with updates from RFC #2822.
///
/// For simplicity, this will be referred to as an RFC #822 address, even
/// though strictly speaking it does not conform to RFC #822. For example,
/// "<a@b>" is not a valid address in RFC #822, but is a valid RFC #2822
/// address.
///
/// This class implements an address (as specified by
/// section 4 "Address Specification" of RFC #2822, which replaced
/// RFC #822).
///
/// This class is useful for both parsing an address into its components,
/// formatting an address from its components,
/// validating the syntax of an address and/or to normalize the string
/// representation of an address.
///
/// To validate the syntax of an address, use the constructor to create
/// an object. If the string was valid, the operation would succeed. If the
/// string was invalid, an exception will be thrown.
///
/// To normalize the string representation of an address, create an
/// object with it and then get its string representation with [toString].
/// The static method [sanitize] does this.
///
/// An RFC #822 "address" can either be a "mailbox" (what a typical email
/// address would be) or a "group" (a named set of zero or more mailboxes).
/// The [Address] class supports both forms, even though groups are rarely used.
/// The [isMailbox] method can be used to determine which form the address
/// is representing.
///
/// Examples of a valid address are:
///
/// - localPart@domain - mailbox with a simple address
/// - displayName<localPart@domain> - mailbox with a name and addr-spec
/// - displayName<@route1,@route2:localPart@domain> - mailbox with a name and route
/// - displayName:; - group with zero explicitly specified mailboxes
/// - displayName:a@a.domain,b@b.domain,c@c.domain; - group with three mailboxes
///
/// Note: this implemention only permits comments (which in RFC #822
/// is text surrounded by parenthesis, possibly nested) only where
/// linear-whitespace can occur.
/// Proper RFC #822 permits comments in other places too.
///
class Address {
  // Members

  String _displayName;
  String _localPart;
  String _domain;
  List<String> _route;
  List<Address> _group;

  String _tmp; // internal use during parsing
  int _offset; // position reached when using the _parseMailbox constructor.

  //--------
  /// Indicates if the address represents a mailbox.
  ///
  /// Returns true if it is a mailbox, returns false if it is a group.
  ///
  bool get isMailbox => (_group == null);

  //--------
  // The display-name can apply to both mailboxes and groups

  /// The display-name part of the address, or null if there is no display-name.
  String get displayName => _displayName;

  //--------
  // The localPart, domain and route only apply to mailboxes

  /// The local-part of the mailbox
  String get localPart {
    if (_group != null) {
      throw new AddressNotMailbox();
    }
    return _localPart;
  }

  /// The domain of the mailbox.
  String get domain {
    if (_group != null) {
      throw new AddressNotMailbox();
    }
    return _domain;
  }

  /// The route (as a list of domains) part of the mailbox, or null if none.
  List<String> get route {
    if (_group != null) {
      throw new AddressNotMailbox();
    }
    return _route;
  }

  //--------
  // The below is only apply to groups

  /// The mailboxes (if any) making up the group, or null if not a group.
  /// This can be an empty list.
  List<Address> get group {
    if (_group == null) {
      throw new AddressNotGroup();
    }
    return _group;
  }

  //----------------------------------------------------------------
  /// Constructor for a mailbox address from component values.
  ///
  Address.mailboxFromParts(String localPart, String domain,
      {String displayName, List<String> route}) {
    if (localPart == null || localPart.isEmpty) {
      throw new AddressInvalid("missing local-part");
    }
    if (domain == null || domain.isEmpty) {
      throw new AddressInvalid("missing domain");
    }

    _group = null;

    _localPart = localPart;
    _domain = domain;
    _displayName = displayName; // can be null
    _route = route; // can be null
  }

  //----------------------------------------------------------------
  /// Constructor for a group address from component valuess.
  ///
  Address.groupFromParts(List<Address> members, {String displayName}) {
    if (members == null) {
      throw new AddressInvalid("missing group members");
    }
    if (displayName == null || displayName.isEmpty) {
      throw new AddressInvalid("missing display-name");
    }

    for (var mb in members) {
      if (!mb.isMailbox) {
        throw new AddressInvalid("group member is not a mailbox");
      }
    }

    _group = members;
    _displayName = displayName; // can be null
  }

  //----------------------------------------------------------------
  /// Constructor from a string value.
  ///
  /// Parses the [str] as an RFC #822 address.
  ///
  /// Throws an [AddressInvalid] exception if it is not a valid
  /// RFC #822 address. A null value or empty string is not a valid RFC #822
  /// address.
  ///
  Address(String str) {
    if (str == null) {
      throw new AddressInvalid("value is null");
    }
    if (str.isEmpty) {
      throw new AddressInvalid("value is an empty string");
    }

    var end = str.length;

    var pos = _skipLinearWhiteSpace(str, 0, end);
    if (pos == end) {
      throw new AddressInvalid("value is a blank string");
    }

    // Parse the address

    pos = _parse(str, pos, end);

    // After which, there should be no more characters in the entire string

    pos = _skipLinearWhiteSpace(str, pos, end);
    if (pos != end) {
      throw new AddressInvalid("unexpected text after address");
    }
  }

  //----------------------------------------------------------------
  /// Internal constructor for creating an address when parsing a group.
  ///
  Address._parseMailbox(String str, int begin, int end) {
    _offset = _parse(str, begin, end);
  }
  //----------------------------------------------------------------

  int _parse(String str, int begin, int end) {
    _displayName = null;
    _localPart = null;
    _domain = null;
    _route = null;
    _group = null;

    // Parse the first word (which is mandatory for all forms of addresses)

    var pos = begin;

    var words = new List<String>();

    var prevPos = null; // to prevent infinite loop when no more words to parse

    while (pos < end) {
      // Parse the first/next word

      pos = _parseWord(str, pos, end);
      var word = _tmp;

      if (word != null) {
        words.add(word);
      } else {
        if (prevPos != null && prevPos == pos) {
          // Not the first time through, but there were no more words parsed
          // and is not one of the special characters in the switch statement
          // below. Blocked by some character.
          if (pos < end) {
            throw new AddressInvalid(
                "invalid address: unexpected character \"${str.substring(pos, pos+1)}\"");
          } else {
            throw new AddressInvalid("invalid address");
          }
        }
      }
      prevPos = pos;

      // The next character might determine what form of address it is

      pos = _skipLinearWhiteSpace(str, pos, end);
      if (end <= pos) {
        throw new AddressInvalid("incomplete address");
      }

      switch (str.substring(pos, pos + 1)) {
        case ".":
        case "@":
          if (words.length != 1) {
            // Note: for a.b.c@d, only "a" is parsed here. The "b" and "c"
            // are to be parsed in _parseSimpleAddress. This is why this test
            // is for length != 1 instead of length.isNotEmpty.
            // The _parseSimpleAddress is used in another context, besides here,
            // which is why it is implemented that way.
            throw new AddressInvalid("simple address is invalid");
          }
          return _parseSimpleAddress(str, pos, end, words);

        case "<":
          return _parseNameAndAddrSpec(str, pos, end, words);

        case ":":
          return _parseGroup(str, pos, end, words);

        default:
          // No special character.
          // Continue with while loop to attempt to parse the next word.
          break;
      }
    }

    // End of string reached, but only parsed words.
    // Never got to a special character
    throw new AddressInvalid("incomplete address");
  }

  //----------------
  //  word *("." word) "@" sub-domain *("." sub-domain)

  int _parseSimpleAddress(String str, int start, int end, List<String> words) {
    assert(start < end);
    assert(words.length == 1);

    var pos = start;
    do {
      switch (str.substring(pos, pos + 1)) {
        case ".":
          // More words in the local-part
          pos = _parseWord(str, pos + 1, end);
          var word = _tmp;
          if (word == null) {
            throw new AddressInvalid(
                "local-part has unexpected final full-stop");
          }
          words.add(word);
          break;

        case "@":
          // End of local-part reached
          _localPart = words.join(".");
          // Parse the domain part
          pos = _parseDomain(str, pos + 1, end);
          return pos; // success

        default:
          throw new AddressInvalid(
              "unexpected character in position ${pos}: \"${str.substring(pos, pos+1)}\"");
      }
      pos = _skipLinearWhiteSpace(str, pos, end);
    } while (pos < end);

    throw new AddressInvalid("incomplete address");
  }

  //----------------
  // Got: 1*word
  // Remaining: "<" [1#("@" domain) ":"] word *("." word) "@" sub-domain *("." sub-domain) ">"

  int _parseNameAndAddrSpec(
      String str, int begin, int end, List<String> words) {
    assert(begin < end);
    assert(str.substring(begin, begin + 1) == "<");

    // Words are the displayName part of the "[displayName] route-addr" form of
    // a mailbox.
    // In RFC #2822 the display-name is optional. In RFC #822 this was known
    // as the _phrase_ and was mandatory.

    if (1 <= words.length) {
      _displayName = words.join(" ");
    } else {
      _displayName = null; // there is no display-name
    }

    // Step over the "<"

    var pos = begin + 1;

    // Try to parse the optional route

    pos = _skipLinearWhiteSpace(str, pos, end);
    if (end <= pos) {
      throw new AddressInvalid("incomplete route-addr address");
    }

    if (str.substring(pos, pos + 1) == "@") {
      pos = _parseRoute(str, pos, end); // route is present
    } else {
      _route = null; // route not present
    }

    // Parse the first word in the addr-spec

    pos = _parseWord(str, pos, end);
    var word = _tmp;
    if (word == null) {
      throw new AddressInvalid("addr-spec does not start with a word");
    }

    pos = _parseSimpleAddress(str, pos, end, [word]);

    // The ">" terminating the route-addr

    pos = _skipLinearWhiteSpace(str, pos, end);
    if (end <= pos) {
      throw new AddressInvalid("incomplete route-addr address");
    }
    if (str.substring(pos, pos + 1) != ">") {
      throw new AddressInvalid("route-addr address missing \">\"");
    }
    pos++;

    // success

    return pos;
  }

  //----------------

  // Got: 1*word
  // Remaining: ":" [#mailbox] ";"

  int _parseGroup(String str, int begin, int end, List<String> words) {
    assert(begin < end);
    assert(str.substring(begin, begin + 1) == ":");

    // Words are the displayName part of the: displayName ":" [#mailbox] ";"

    if (words.isEmpty) {
      throw new AddressInvalid("group missing display-name");
    }
    _displayName = words.join(" ");

    // Step over ":"

    var pos = begin + 1;

    // Parse [mailbox-list] ";"

    _group = new List<Address>();

    var expectingMailbox = null; // null since mailbox-list can be empty

    do {
      if (pos < end) {
        var char = str.substring(pos, pos + 1);
        if (char == ";") {
          // end of group reached
          if (expectingMailbox != null && expectingMailbox) {
            throw new AddressInvalid("group has unexpected final comma");
          }
          return pos + 1;
        } else if (char == ",") {
          if (_group.isEmpty) {
            throw new AddressInvalid("group has unexpected initial comma");
          }
          if (expectingMailbox != null && expectingMailbox) {
            throw new AddressInvalid("group has unexpected extra comma");
          }
          pos++; // step over the comma
          expectingMailbox = true;
        } else {
          if (expectingMailbox != null && !expectingMailbox) {
            throw new AddressInvalid("group is missing comma");
          }
          var mailbox = new Address._parseMailbox(str, pos, end);
          if (!mailbox.isMailbox) {
            throw new AddressInvalid("nested groups are not permitted");
          }
          _group.add(mailbox);
          pos = mailbox._offset;
          expectingMailbox = false;
        }

        pos = _skipLinearWhiteSpace(str, pos, end);
      }
    } while (pos < end);

    throw new AddressInvalid("group is incomplete");
  }

  //----------------

  // Parsing: 1#("@" domain) ":"

  int _parseRoute(String str, int begin, int end) {
    assert(str != null);
    assert(begin < end);
    assert(str.substring(begin, begin + 1) == "@");

    var pos = begin;

    _route = new List<String>();

    var expectingDomain = true;

    while (begin < end) {
      switch (str.substring(pos, pos + 1)) {
        case "@":
          if (!expectingDomain) {
            throw new AddressInvalid("route is missing comma");
          }
          try {
            pos = _parseDomain(str, pos + 1, end);
            _route.add(_domain);
            _domain = null; // just using the _parseDomain method temporally
            expectingDomain = false;
          } on AddressInvalid {
            throw new AddressInvalid("route has bad domain");
          }
          break;

        case ",":
          if (expectingDomain) {
            throw new AddressInvalid("route has unexpected extra comma");
          }
          pos++;
          expectingDomain = true;
          break;

        case ":":
          // End of route
          if (expectingDomain) {
            throw new AddressInvalid("route has unexpected final comma");
          }
          return pos + 1; // success
      }
      pos = _skipLinearWhiteSpace(str, pos, end);
    }

    throw new AddressInvalid("route is missing terminating colon");
  }

  //----------------

  int _parseDomain(String str, int begin, int end) {
    assert(begin <= end);

    var pos = begin;

    // EBNF: domain = sub-domain *("." sub-domain)
    // EBNF: sub-domain = domain-ref / domain-literal
    // EBNF: domain-ref = atom

    _domain = "";
    while (pos < end) {
      pos = _skipLinearWhiteSpace(str, pos, end);

      int subdomainEnd;
      if (str.substring(pos, pos + 1) != "[") {
        subdomainEnd = _parseAtom(str, pos, end);
      } else {
        subdomainEnd = _parseDomainLiteral(str, pos, end);
      }

      if (_tmp == null) {
        if (_domain.isEmpty) {
          throw new AddressInvalid("domain has unexpected initial full-stop");
        } else {
          throw new AddressInvalid("domain has unexpected extra full-stop");
        }
      }
      _domain += _tmp;
      pos = subdomainEnd;

      pos = _skipLinearWhiteSpace(str, pos, end);
      if (end <= pos) {
        return pos; // end of domain, because no more text in str to process
      }
      if (str.substring(pos, pos + 1) != ".") {
        return pos; // end of domain, because there is not another sub-domain
      }

      // Domain has more sub-domains

      _domain += ".";
      pos++;
    }

    if (_domain.isEmpty) {
      throw new AddressInvalid("domain is missing");
    } else {
      throw new AddressInvalid("domain has unexpected final full-stop");
    }
  }

  //----------------

  int _parseDomainLiteral(String str, int begin, int end) {
    if (str.substring(begin, begin + 1) != "[") {
      throw new AddressInvalid("domain-literal does not start with \"[\"");
    }

    var n = begin + 1;
    while (n < end) {
      var ch = str.codeUnitAt(n);
      if (ch == "\\".codeUnitAt(0)) {
        // Quoted pair
        n++;
        if (end < n) {
          throw new AddressInvalid("domain-literal not terminated");
        }
        _tmp += str.substring(n, n + 1);
        n++;
      } else if (33 <= ch &&
          ch <= 126 &&
          "\\[]\n".indexOf(new String.fromCharCode(ch)) < 0) {
        // Valid character for an dtext
        _tmp += str.substring(n, n + 1);
        n++;
      } else if (ch != "]".codeUnitAt(0)) {
        _tmp = str.substring(begin, n);
        return n;
      } else {
        throw new AddressInvalid("domain-literal not terminated with \"]\"");
      }
    }

    throw new AddressInvalid("domain-literal not terminated with \"]\"");
  }

  //----------------

  int _parseComment(String str, int begin, int end) {
    assert(begin < end);
    assert(str.substring(begin, begin + 1) == "(");

    // EBNF:

    var nestingDepth = 0;

    _tmp = "";
    var n = begin;
    while (n < end) {
      switch (str.substring(n, n + 1)) {
        case "(":
          // Start of a comment
          nestingDepth++;
          break;
        case ")":
          // End of a comment
          nestingDepth--;
          if (nestingDepth == 0) {
            return n + 1;
          }
          break;
        case "\\":
          // Escaped character
          if (str.length < n) {
            throw new AddressInvalid("Unterminated comment");
          }
          _tmp += str.substring(n + 1, n + 2);
          n++;
          break;
        default:
          // Normal character
          _tmp += str.substring(n, n + 1);
          break;
      }
      n++;
    }
    throw new AddressInvalid("Unterminated comment");
  }

  //----------------
  // Attempts to parse the next word.
  //
  // If successful, the word is placed in [_tmp] and it returns the next
  // position after the word.

  int _parseWord(String str, int begin, int end) {
    assert(begin < end);

    // EBNF: word = atom / quoted-string

    var pos = _skipLinearWhiteSpace(str, begin, end);

    if (pos < end) {
      if (str.substring(pos, pos + 1) != "\"") {
        return _parseAtom(str, pos, end);
      } else {
        return _parseQuotedString(str, pos, end);
      }
    } else {
      _tmp = null;
      return pos;
    }
  }

  //----------------

  int _parseAtom(String str, int begin, int end) {
    var n = begin;
    while (n < end) {
      if (!_isAtomChar(str, n)) {
        break; // terminated by non-word character
      }
      n++;
    }
    if (begin < n) {
      _tmp = str.substring(begin, n);
    } else {
      _tmp = null; // no word found
    }
    return n;
  }

  //----------------

  int _parseQuotedString(String str, int begin, int end) {
    assert(begin < end);
    assert(str.substring(begin, begin + 1) == '"');

    _tmp = "";
    var n = begin + 1;
    while (n < end) {
      switch (str.substring(n, n + 1)) {
        case "\"":
          // End quote
          return n + 1;
        case "\\":
          // Escaped character
          if (str.length < n) {
            throw new AddressInvalid("Incomplete escape in quoted string");
          }
          _tmp += str.substring(n + 1, n + 2);
          n++;
          break;
        default:
          // Normal character
          _tmp += str.substring(n, n + 1);
          break;
      }
      n++;
    }
    throw new AddressInvalid("Unterminated quoted string");
  }

  //----------------

  int _skipLinearWhiteSpace(String str, int begin, int end) {
    var pos = begin;

    while (pos < end) {
      var ch = str.substring(pos, pos + 1);

      if (ch == " " || ch == "\t") {
        pos++;
      } else if (ch == "(") {
        pos = _parseComment(str, pos, end);
      } else {
        break;
      }
    }

    return pos;
  }

  //----------------------------------------------------------------
  /// Tests if character at position [pos] in the [str] can appear in an atom.

  static bool _isAtomChar(String str, int pos) {
    var ch = str.codeUnitAt(pos);
    if (33 <= ch &&
        "()<>@,;:\\\".[]".indexOf(new String.fromCharCode(ch)) < 0) {
      return true;
    } else {
      return false;
    }
  }

  //----------------------------------------------------------------
  /// Returns the simple-address in a mailbox address.
  ///
  /// That is, returns _localPart@domain_, ignoring any display-name
  /// or routes.
  ///
  /// Throws an exception if the address is not a mailbox (i.e. if it
  /// is a group).
  ///
  String simpleAddress() {
    if (!isMailbox) {
      throw new AddressNotMailbox();
    }

    var addrSpec = _formatAtomOrQuotedString(_localPart);

    addrSpec += "@";
    addrSpec += _domain; // TODO: quote this if needed

    return addrSpec;
  }

  String toString() {
    if (isMailbox) {
      assert(_group == null);
      assert(_localPart != null && _localPart.isNotEmpty);
      assert(_domain != null && _domain.isNotEmpty);

      var addrSpec = _formatAtomOrQuotedString(_localPart);

      addrSpec += "@";
      addrSpec += _domain; // TODO: quote this if needed

      // Route

      if (_route != null) {
        // Address with route
        var r = "";
        for (var domain in _route) {
          r = r + "@" + domain;
        }
        addrSpec = "${r}:${addrSpec}";
      }

      // Optional phase

      if (_displayName == null && _route == null) {
        // Does not need < >
        return addrSpec;
      } else {
        // Need < >
        return "\"${_displayName}\" <${addrSpec}>";
      }
    } else {
      // Group
      assert(_group != null);
      assert(_localPart == null);
      assert(_domain == null);
      assert(_route == null);

      var str;
      if (_displayName == null) {
        throw new AddressInvalid("Group cannot have no display-name");
      } else {
        str = "${_displayName}:";
      }

      var first = true;
      for (var mailbox in _group) {
        if (first) {
          first = false;
        } else {
          str += ",";
        }
        str += mailbox.toString();
      }

      str += ";";
      return str;
    }
  }

  //----------------

  static String _formatAtomOrQuotedString(String str) {
    // Check if string contains characters that need to be quoted

    var needsQuoting = false;
    for (int n = 0; n < str.length; n++) {
      if (!_isAtomChar(str, n)) {
        needsQuoting = true;
        break;
      }
    }

    // Produce the localPart@domain

    var result;
    if (!needsQuoting) {
      // atom
      result = str;
    } else {
      // quoted-string
      result = '"';
      for (int n = 0; n < str.length; n++) {
        if (_isAtomChar(str, n)) {
          result += str.substring(n, n + 1);
        } else {
          var ch = str.substring(n, n + 1);
          if (ch == '"' || ch == "\\" || ch == "\r") {
            result += "\\${ch}";
          } else {
            result += str.substring(n, n + 1);
          }
        }
      }
      result += '"';
    }
    return result;
  }

  //----------------------------------------------------------------
  /// Returns a sanitized version of the address.
  ///
  /// Throws an [AddressInvalid] if the [address] is not
  /// a valid RFC #822 address.
  ///
  static String sanitize(String address) {
    return new Address(address).toString();
  }
}

//EOF
