## 2.5.0
* move exceptions outside `src`.

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
