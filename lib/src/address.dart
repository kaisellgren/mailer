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

/// An RFC #5322 address with support for RFC #6531 for UTF-8.
///
/// This class implements an address (as specified by
/// section 3.4 "Address Specification" of RFC #5822, which obsoleted
/// RFC #2822, which obsoleted RFC #822).
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
/// An RFC #5822 "address" can either be a "mailbox" (what a typical email
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
class Address {
  // Members

  StringBuffer _tmp; // internal use during parsing
  int _offset; // position reached when using the _parseMailbox constructor.

  //--------
  /// Indicates if the address represents a mailbox.
  ///
  /// Returns true if it is a mailbox, returns false if it is a group.
  ///
  bool get isMailbox => (groupMailboxes == null);

  //--------
  // The display-name can apply to both mailboxes and groups

  /// The display-name part of the address, or null if there is no display-name.
  /// Available for both mailbox addresses and group addresses.
  ///
  String displayName;

  //--------
  // The localPart, domain and route only apply to mailboxes

  /// The local-part of the mailbox
  ///
  /// Only available for a group address.
  String localPart;

  /// The domain of the mailbox.
  ///
  /// Only available for mailbox addresses.
  ///
  String domain;

  /// The route (as a list of domains) part of the mailbox, or null if none.
  ///
  /// Only available for mailbox addresses.
  ///
  List<String> route;

  //--------
  // The below is only apply to groups

  /// The mailboxes (if any) making up the group, or null if not a group.
  /// This can be an empty list.
  ///
  /// Only available for group addresses.
  ///
  List<Address> groupMailboxes;

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

    groupMailboxes = null;

    localPart = localPart;
    domain = domain;
    displayName = displayName; // can be null
    route = route; // can be null
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

    groupMailboxes = members;
    displayName = displayName; // can be null
  }

  //----------------------------------------------------------------
  /// Constructor from a string value.
  ///
  /// Parses the [str] as an RFC #5822 address.
  ///
  /// Throws an [AddressInvalid] exception if it is not a valid
  /// RFC #5822 address. A null value or empty string is not a valid RFC #5822
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

    var pos = _skipCFWS(str, 0, end);
    if (pos == end) {
      throw new AddressInvalid("value is a blank string");
    }

    // Parse the address

    pos = _parseAddress(str, pos, end);

    // After which, there should be no more characters in the entire string

    pos = _skipCFWS(str, pos, end);
    if (pos != end) {
      throw new AddressInvalid("unexpected text after address");
    }
  }

  //----------------------------------------------------------------
  /// Internal constructor for creating an address
  ///
  /// This is invoked when parsing an address that is a member of a group.
  /// Sets the [_offset] to the position in the string that is reached.
  ///
  Address._parseMailbox(String str, int begin, int end) {
    _offset = _parseAddress(str, begin, end);
    if (!this.isMailbox) {
      throw new AddressInvalid("nested groups are not permitted");
    }
  }

  //----------------------------------------------------------------

  int _parseAddress(String str, int begin, int end) {
    displayName = null;
    localPart = null;
    domain = null;
    route = null;
    groupMailboxes = null;

    // According to RFC #5822, an address is:
    //
    // address         =   mailbox / group
    //
    // mailbox         =   name-addr / addr-spec
    //
    // name-addr       =   [display-name] angle-addr
    //
    // angle-addr      =   [CFWS] "<" addr-spec ">" [CFWS] / obs-angle-addr
    //
    // group           =   display-name ":" [group-list] ";" [CFWS]
    //
    // display-name    =   phrase
    //
    // addr-spec       =   local-part "@" domain
    //
    // local-part      =   dot-atom / quoted-string / obs-local-part
    //
    // phrase          =   1*word / obs-phrase
    //
    // dot-atom        =   [CFWS] dot-atom-text [CFWS]
    //
    // dot-atom-text   =   1*atext *("." 1*atext)
    //
    // quoted-string   =   [CFWS] DQUOTE *([FWS] qcontent) [FWS] DQUOTE [CFWS]
    //
    // obs-local-part  =   word *("." word)
    //
    // obs-phrase      =   word *(word / "." / CFWS)
    //
    // word            =   atom / quoted-string
    //
    // atom            =   [CFWS] 1*atext [CFWS]
    //
    // obs-angle-addr  =   [CFWS] "<" obs-route addr-spec ">" [CFWS]

    //---------
    // For the purposes of parsing, it has been transformed into:
    //
    // address = name-addr / addr-spec / group
    //
    // address = ( [display-name] angle-addr ) /
    //           ( local-part "@" domain ) /
    //           ( display-name ":" [group-list] ";" [CFWS] )
    //
    // address = ( [phrase] [CFWS] "<" addr-spec ">" [CWFS] / obs-angle-addr ) /
    //           ( dot-atom / quoted-string / obs-local-part "@" domain ) /
    //           ( phrase ":" [group-list] ";" [CFWS] )
    //
    // address = ( [phrase] [CFWS] "<" addr-spec ">" [CWFS] ) /
    //           ( [phrase] [CFWS] "<" obs-route addr-spec ">" [CFWS] ) /
    //           ( dot-atom / quoted-string / obs-local-part "@" domain ) /
    //           ( phrase ":" [group-list] ";" [CFWS] )
    //
    // address = ( [phrase] [CFWS] "<" addr-spec ">" [CWFS] ) /
    //           ( [phrase] [CFWS] "<" obs-route addr-spec ">" [CFWS] ) /
    //           ( [CFWS] dot-atom-text [CFWS] "@" domain ) /
    //           ( quoted-string "@" domain ) /
    //           ( word *("." word) "@" domain ) /
    //           ( phrase ":" [group-list] ";" [CFWS] )
    //
    // address = ( [1*word / obs-phrase] [CFWS] "<" addr-spec ">" [CWFS] ) /
    //           ( [1*word / obs-phrase] [CFWS] "<" obs-route addr-spec ">" [CFWS] ) /
    //           ( [CFWS] dot-atom-text [CFWS] "@" domain ) /
    //           ( quoted-string "@" domain ) /
    //           ( word *("." word) "@" domain ) /
    //           ( 1*word / obs-phrase ":" [group-list] ";" [CFWS] )
    //
    // address = ( [1*word] [CFWS] "<" addr-spec ">" [CWFS] ) /
    //           ( [ word *(word / "." / CFWS) ] [CFWS] "<" addr-spec ">" [CWFS] ) /
    //           ( [1*word] [CFWS] "<" obs-route addr-spec ">" [CFWS] ) /
    //           ( [ word *(word / "." / CFWS) ] [CFWS] "<" obs-route addr-spec ">" [CFWS] ) /
    //           ( [CFWS] dot-atom-text [CFWS] "@" domain ) /
    //           ( quoted-string "@" domain ) /
    //           ( word *("." word) "@" domain ) /
    //           ( 1*word ":" [group-list] ";" [CFWS] )
    //           ( word *(word / "." / CFWS) ":" [group-list] ";" [CFWS] )
    //
    // So the address starts with one or more words followed by "<", ".", "@", ":".

    var pos = begin;

    var words = new List<String>();

    var prevPos = null; // to prevent infinite loop when no more words to parse

    // Parse words until we reach a special character.

    while (pos < end) {
      // Parse the first/next word

      pos = _parseWord(str, pos, end);
      var word = _tmp;

      if (word != null) {
        words.add(word.toString());
      } else {
        if (prevPos != null && prevPos == pos) {
          // Not the first time through, but there were no more words parsed
          // and is not one of the special characters in the switch statement
          // below. Blocked by some character.
          if (pos < end) {
            throw new AddressInvalid(
                "invalid address: unexpected character \"${str.substring(pos, pos + 1)}\"");
          } else {
            throw new AddressInvalid("invalid address");
          }
        }
      }
      prevPos = pos;

      // The next character might determine what form of address it is

      pos = _skipCFWS(str, pos, end);
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
          return _parseAddrSpec(str, pos, end, words);

        case "<":
          return _parseAngleAddr(str, pos, end, words);

        case ":":
          return _parseGroup(str, pos, end, words);

        default:
          // No special character.
          // Continue with while loop to attempt to parse the next word.
          break;
      }
    }

    // End of string reached, but still only parsed words.
    // Never got to a special character
    throw new AddressInvalid("incomplete address");
  }

  //----------------
  // addr-spec       =   local-part "@" domain
  //
  // local-part      =   dot-atom / quoted-string / obs-local-part
  //
  // domain          =   dot-atom / domain-literal / obs-domain
  //
  // atom            =   [CFWS] 1*atext [CFWS]
  //
  // dot-atom-text   =   1*atext *("." 1*atext)
  //
  // dot-atom        =   [CFWS] dot-atom-text [CFWS]

  // The [words] contains the first word in the local-part.

  int _parseAddrSpec(String str, int start, int end, List<String> words) {
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
          words.add(word.toString());
          break;

        case "@":
          // End of local-part reached
          localPart = words.join(".");
          // Parse the domain part
          pos = _parseDomain(str, pos + 1, end);
          return pos; // success

        default:
          throw new AddressInvalid("unexpected character in local-part");
      }
    } while (pos < end);

    throw new AddressInvalid("incomplete address");
  }

  //----------------
  // Got: 1*word [CFWS]
  // Remaining: "<" addr-spec ">" [CFWS] / obs-angle-addr
  //
  // The [words] contain the optional display-name.

  int _parseAngleAddr(String str, int begin, int end, List<String> words) {
    assert(begin < end);
    assert(str.substring(begin, begin + 1) == "<");

    // angle-addr      =   [CFWS] "<" addr-spec ">" [CFWS] / obs-angle-addr

    // Words are the displayName part of the "[displayName] route-addr" form of
    // a mailbox.
    // In RFC #2822 the display-name is optional. In RFC #822 this was known
    // as the _phrase_ and was mandatory.

    if (1 <= words.length) {
      displayName = words.join(" ");
    } else {
      displayName = null; // there is no display-name
    }

    // Step over the "<"

    var pos = begin + 1;

    // Try to parse the optional route

    pos = _skipCFWS(str, pos, end);
    if (end <= pos) {
      throw new AddressInvalid("incomplete route-addr address");
    }

    if (str.substring(pos, pos + 1) == "@" ||
        str.substring(pos, pos + 1) == ",") {
      pos = _parseRoute(str, pos, end); // route is present
    } else {
      route = null; // route not present
    }

    // Parse the first word in the addr-spec (so we can use the
    // _parseSimpleAddress method which requires the first word to have
    // already been parsed.

    pos = _parseWord(str, pos, end);
    var word = _tmp;
    if (word == null) {
      throw new AddressInvalid("addr-spec does not start with a word");
    }

    pos = _parseAddrSpec(str, pos, end, [word.toString()]);

    // The ">" terminating the route-addr

    pos = _skipCFWS(str, pos, end);
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
    displayName = words.join(" ");

    // Step over ":"

    var pos = begin + 1;

    // Parse [mailbox-list] ";"

    groupMailboxes = new List<Address>();

    bool expectingMailbox = null; // null since mailbox-list can be empty

    do {
      if (pos < end) {
        var char = str.substring(pos, pos + 1);
        if (char == ";") {
          // end of group reached
          if (expectingMailbox ?? false) {
            throw new AddressInvalid("group has unexpected final comma");
          }
          return pos + 1;
        } else if (char == ",") {
          if (groupMailboxes.isEmpty) {
            throw new AddressInvalid("group has unexpected initial comma");
          }
          if (expectingMailbox ?? false) {
            throw new AddressInvalid("group has unexpected extra comma");
          }
          pos++; // step over the comma
          expectingMailbox = true;
        } else {
          if (expectingMailbox != null && !expectingMailbox) {
            throw new AddressInvalid("group is missing comma");
          }
          var mailbox = new Address._parseMailbox(str, pos, end);
          groupMailboxes.add(mailbox);
          pos = mailbox._offset;
          expectingMailbox = false;
        }

        pos = _skipCFWS(str, pos, end);
      }
    } while (pos < end);

    throw new AddressInvalid("group is incomplete");
  }

  //----------------

  // Parsing: 1#("@" domain) ":"

  int _parseRoute(String str, int begin, int end) {
    assert(str != null);
    assert(begin < end);
    assert(str.substring(begin, begin + 1) == "@" ||
        str.substring(begin, begin + 1) == ",");

    // obs-route       =   obs-domain-list ":"
    //
    // obs-domain-list =   *(CFWS / ",") "@" domain
    //                     *("," [CFWS] ["@" domain])

    var pos = begin;

    route = new List<String>();

    var expectingDomain = true;

    while (begin < end) {
      switch (str.substring(pos, pos + 1)) {
        case "@":
          if (!expectingDomain) {
            throw new AddressInvalid("route missing a comma");
          }
          try {
            pos = _parseDomain(str, pos + 1, end);
            route.add(domain);
            domain = null; // just using the _parseDomain method for its
            // side effect of getting a domain. This is not the real domain value.
            expectingDomain = false;
          } on AddressInvalid {
            throw new AddressInvalid("route has bad domain");
          }
          break;

        case ",":
          pos++;
          expectingDomain = true;
          break;

        case ":":
          // End of route
          if (route.isEmpty) {
            throw new AddressInvalid("route must have at least one domain");
          }
          return pos + 1; // success
      }
      pos = _skipCFWS(str, pos, end);
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

    domain = "";
    while (pos < end) {
      pos = _skipCFWS(str, pos, end);

      int subdomainEnd;
      if (str.substring(pos, pos + 1) != "[") {
        subdomainEnd = _parseAtom(str, pos, end);
      } else {
        subdomainEnd = _parseDomainLiteral(str, pos, end);
      }

      if (_tmp == null) {
        if (domain.isEmpty) {
          throw new AddressInvalid("domain has unexpected initial full-stop");
        } else {
          throw new AddressInvalid("domain has unexpected extra full-stop");
        }
      }
      domain += _tmp.toString();
      pos = subdomainEnd;

      pos = _skipCFWS(str, pos, end);
      if (end <= pos) {
        return pos; // end of domain, because no more text in str to process
      }
      if (str.substring(pos, pos + 1) != ".") {
        return pos; // end of domain, because there is not another sub-domain
      }

      // Domain has more sub-domains

      domain += ".";
      pos++;
    }

    if (domain.isEmpty) {
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
      if (ch == $backslash) {
        // Quoted pair
        n++;
        if (end < n) {
          throw new AddressInvalid("domain-literal not terminated");
        }
        _tmp.writeCharCode(str.codeUnitAt(n));
        n++;
      } else if (33 <= ch &&
          ch <= 126 &&
          (ch != $backslash &&
              ch != $lbracket &&
              ch != $rbracket &&
              ch != $lf)) {
        // Valid character for an dtext
        _tmp.writeCharCode(ch);
        n++;
      } else if (ch != $rbracket) {
        _tmp = new StringBuffer(str.substring(begin, n));
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

    _tmp = new StringBuffer();
    var n = begin;
    while (n < end) {
      final ch = str.codeUnitAt(n);
      switch (ch) {
        case $lparen:
          // Start of a comment
          nestingDepth++;
          break;
        case $rparen:
          // End of a comment
          nestingDepth--;
          if (nestingDepth == 0) {
            return n + 1;
          }
          break;
        case $backslash:
          // Escaped character
          if (str.length < n) {
            throw new AddressInvalid("Unterminated comment");
          }
          _tmp.writeCharCode(str.codeUnitAt(n + 1));
          n++;
          break;
        default:
          // Normal character
          _tmp.writeCharCode(ch);
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

    var pos = _skipCFWS(str, begin, end);

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
    // RFC #5822 defines:
    //
    // atom            =   [CFWS] 1*atext [CFWS]

    var n = _skipCFWS(str, begin, end);
    n = _parseAtext(str, n, end);
    return _skipCFWS(str, n, end);
  }

  //----------------
  // Sets [_tmp] to the parsed value.

  int _parseAtext(String str, int begin, int end) {
    //
    // 1*atext

    var n = begin;
    while (n < end) {
      if (!_isAtomChar(str.codeUnitAt(n))) {
        break; // terminated by non-word character
      }
      n++;
    }
    if (begin < n) {
      _tmp = new StringBuffer(str.substring(begin, n));
    } else {
      _tmp = null; // no word found
    }

    return n;
  }

  //----------------
  int _parseQuotedString(String str, int begin, int end) {
    assert(begin < end);
    assert(str.substring(begin, begin + 1) == '"');

    // quoted-string = [CFWS]  DQUOTE *([FWS] qcontent) [FWS] DQUOTE [CFWS]

    _tmp = new StringBuffer();
    var n = begin + 1;
    while (n < end) {
      final ch = str.codeUnitAt(n);
      switch (ch) {
        case $double_quote:
          // End quote
          return _skipCFWS(str, n + 1, end);

        case $backslash:
          // Escaped character
          if (str.length < n) {
            throw new AddressInvalid("Incomplete escape in quoted string");
          }
          _tmp.writeCharCode(str.codeUnitAt(n + 1));
          n++;
          break;
        default:
          // Normal character
          _tmp.writeCharCode(ch);
          break;
      }
      n++;
    }
    throw new AddressInvalid("Unterminated quoted string");
  }

  //----------------
  // Skips over Comments and/or Folding White Space.

  int _skipCFWS(String str, int begin, int end) {
    var pos = begin;

    while (pos < end) {
      var ch = str.codeUnitAt(pos);
      if (ch == $space || ch == $tab) {
        pos++;
      } else if (ch == $lparen) {
        pos = _parseComment(str, pos, end);
      } else {
        break;
      }
    }

    return pos;
  }

  //----------------------------------------------------------------
  /// Tests if character at position [pos] in the [str] can appear in an atom.

  static bool _isAtomChar(int ch) {
    // A character from the "atext" production in RFC #5822.
    return ($a <= ch && ch <= $z) ||
        ($A <= ch && ch <= $Z) ||
        ($0 <= ch && ch <= $9) ||
        _atomCharCodes.contains(ch) ||
        127 < ch;
  }

  static final Set<int> _atomCharCodes =
      "!#\$%&'*+-/=?^_`{|}~".codeUnits.toSet();

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

    var addrSpec = _formatDotted(localPart);

    addrSpec += "@";
    addrSpec += _formatDotted(domain); // TODO: quote this if needed

    return addrSpec;
  }

  String toString() {
    if (isMailbox) {
      // Mailbox
      assert(groupMailboxes == null);
      assert(localPart != null && localPart.isNotEmpty);
      assert(domain != null && domain.isNotEmpty);

      var addrSpec = simpleAddress();

      // Route

      if (route != null) {
        // Address with route
        var r = "";
        for (var domain in route) {
          r = r + "@" + domain;
        }
        addrSpec = "${r}:${addrSpec}";
      }

      // Optional phase

      if (displayName == null && route == null) {
        // Does not need < >
        return addrSpec;
      } else {
        // Need < >
        return "${_formatAtomOrQuotedString(displayName)} <${addrSpec}>";
      }
    } else {
      // Group
      assert(groupMailboxes != null);
      assert(localPart == null);
      assert(domain == null);
      assert(route == null);

      String str;
      if (displayName == null) {
        throw new AddressInvalid("Group cannot have no display-name");
      } else {
        str = "${displayName}:";
      }

      var first = true;
      for (var mailbox in groupMailboxes) {
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

  static String _formatDotted(String str) {
    return str.split(".").map((s) => _formatAtomOrQuotedString(s)).join(".");
  }

  //----------------

  static String _formatAtomOrQuotedString(String str) {
    // Check if string contains characters that need to be quoted

    // It also needs quoting if it starts or ends with whitespace
    // or contains multiple whitespaces in sequence

    var ch;
    var needsQuoting = str.isEmpty ||
        (ch = str.codeUnitAt(0)) == $space ||
        ch == $tab // starts with whitespace
        ||
        (ch = str.codeUnitAt(str.length - 1)) == $space ||
        ch == $tab; // ends with whitespace

    var prevCharWasWhitespace = false;
    for (int n = 0; n < str.length; n++) {
      var ch = str.codeUnitAt(n);
      var isWhiteSpace = ch == $space || ch == $tab;
      if (!_isAtomChar(ch) && !isWhiteSpace) {
        needsQuoting = true;
        break;
      }
      if (isWhiteSpace) {
        if (prevCharWasWhitespace) {
          needsQuoting = true; // double whitespace
          break;
        }
        prevCharWasWhitespace = true;
      } else {
        prevCharWasWhitespace = false;
      }
    }

    // Produce the localPart@domain

    if (!needsQuoting) {
      // atom
      return str;
    } else {
      // quoted-string
      final result = new StringBuffer('"');
      for (int n = 0; n < str.length; n++) {
        final ch = str.codeUnitAt(n);
        if (_isAtomChar(ch)) {
          result.writeCharCode(ch);
        } else {
          if (ch == $double_quote || ch == $backslash || ch == $cr)
            result.write("\\");
          result.writeCharCode(ch);
        }
      }
      result.write('"');
      return result.toString();
    }
  }

  //----------------------------------------------------------------
  /// Returns a sanitized version of the address.
  ///
  /// Throws an [AddressInvalid] if the [address] is not
  /// a valid RFC #5822 address.
  ///
  static String sanitize(String address) {
    return new Address(address).toString();
  }
}

//EOF
