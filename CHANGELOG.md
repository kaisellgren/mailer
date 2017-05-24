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
