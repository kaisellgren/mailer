Mailer
==

**Mailer** is an easy to use library for composing and sending emails in Dart.

Mailer supports file attachments, HTML emails and multiple transport methods.

## Features

* Plaintext and HTML emails
* Unicode support
* Attachments
* Secure (filters and sanitizes all fields context-wise)
* Use any SMTP server like Gmail, Live, SendGrid, Amazon SES
* SSL/TLS support
* Pre-configured services (Gmail, Live, Mail.ru, etc.). Just fill in your username and password.

## Filing bug tickets

Please call `printDebugInformation()` from the mailer package and send the output along with your helpful explanation of what went wrong.

## TODO

* All possible SMTP authentication methods (now just LOGIN)
* Sendmail
* Stream attachments
* String-based attachments

## Examples

### Sending an email with SMTP

See [gmail example](example/send_gmail.dart).

## License
This library is licensed under MIT.
