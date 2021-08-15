## 5.0.2
* Fix Null error when closing smtp connection
  Thanks: https://github.com/hpoul

## 5.0.1
* Fix null-safety migration bug with bad type cast.

## 5.0.0
* minor interface changes.  Some are now const / final objects.
* added a lot of tests
* names of addresses may contain unicode characters now  
  still no punycode support!

## 4.0.0
* null safety and cleanups
  Thanks: https://github.com/bsutton
  
## 3.3.0
* add sendgrid smtp server
  Thanks: https://github.com/rohanthacker

## 3.2.1
* Fix compile time bug. 😳

## 3.2.0
* The generation of the mailbox address is done via `Address.toString()`, so application can override it to provide its own sanitization, if necessary.

## 3.1.0
* Improve gmail integration utilities.
* Discourage use of username/password authentication through deprecation.

## 3.0.4
* fix null pointer when server doesn't support EHLO (#121)

## 3.0.3
* fix splitting of text for base64 conversion.

## 3.0.2
* some (dart) file operations changed the return type from `List<int>` to `Uint8List`
  Implemented the proposed fixes from: https://groups.google.com/forum/#!topic/flutter-announce/LTe4SYU8-0Q

## 3.0.1
* allow older pedantic version to make mailer compatible with flutter.

## 3.0.0
* NO BUGFIXES.  There is no *need* to update!
* remove dart 1 compatible code.  mailer does require dart 2.2.2 or higer now.
* remove `catchExceptions` flag.  mailer now always throws.
* change return value of `send` from `List<SendReport>` to `SendReport`
* add persistent connection (idea from https://github.com/jodinathan)
* add xoauth2 authentication method (see examples)

## 2.5.1
* assign `catchExceptions` if null 

## 2.5.0
* export exceptions.

## 2.4.0
* add `catchExceptions` flag to `send` command.  (issue #90)

## 2.3.0
* add timeout option.  (https://github.com/pjkroll)
* add `catchExceptions` flag (currently true, but default will change to false)
  improve exceptions.
* remove username from authentication failure exception (see issue #79)

## 2.2.1
* fix regular expression which is used to validate the name of an email address. 

## 2.2.0
* add qq smtp server definition

## 2.1.2
* improve exception when server response does not match.

## 2.1.1
* if a header value is `null` send empty string instead.
* if mime library fails to identify content use `text/plain` and `application/octet-stream`  
  as defaults.
* mention mailer2 and mailer3 in README

## 2.1.0
* provide smtp_servers in smtp_server.dart

## 2.0.2
* added smtp configuration for mailgun.org

## >1.1.4 \<2.0.2
Please see README and commits.

## 1.1.4
* Remove extra trailing `\r\n` from messages as some servers may interpret it as an empty
 command and send back an error code after success code

## 1.1.3
* Fix occasional issue with completer already completed. Due to an error with SMTP server
closing connection after sending the email.

## 1.1.2
* Fix new lines sent to server to be proper `\r\n` format

## 1.1.1
* loosen crypto dependency to '>=0.9.0 <3.0.0' as suggested in the
    [crypto changelog](https://github.com/dart-lang/crypto/blob/master/CHANGELOG.md#200)

## 1.1.0
* merge crypto util fix and update example
* upgrade unittest to test and move it to dev_dependencies
* added OpenMailBoxSmtpOptions
* improve address parsing and sanitization (from hoylen)
* cleanup chunkEncodedBytes and associated test
* update example to allow CC and BCC

## 1.0.1
* add simple example/send_gmail.data
* fix pubspec to pull crypto 0.9.0

## 1.0.0 - Oct 4, 2015
* initial release
