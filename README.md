# mailer


**mailer** is an easy to use library for composing and sending emails in Dart.

Mailer supports file attachments and HTML emails.

## Dart2 support

Support for dart2 has been added in version ^1.2.0  

Version ^2.0.0 is a rewrite (it too supports dart1.x and dart2).

Even though the API for ^2.0.0 has slightly changed, *most* programs will probably
continue to work with deprecation warnings.

## SMTP definitions

Mailer provides configurations for a few common SMTP servers.

Please create merge requests for missing configurations.

* Copy `lib/smtp_server/gmail.dart` to `lib/smtp_server/xxx.dart`
* Adapt the code.  (See `lib/smtp_server.dart` for possible arguments)
* Create a pull request.

In a lot of cases you will find a configuration in `legacy.dart`

## Features

* Plaintext and HTML emails
* Unicode support
* Attachments
* Secure (filters and sanitizes all fields context-wise)
* Use any SMTP server like Gmail, Live, SendGrid, Amazon SES
* SSL/TLS support
* Pre-configured services (Gmail, Yahoo, Hotmail, etc.). Just fill in your username and password.

## TODO *HELP WANTED*

* Correct encoding of non ASCII mail addresses.
* Reintegrate address validation from version 1.*
* Improve Header types.  (see [ir_header.dart](lib/src/smtp/internal_representation/ir_header.dart))  
We should choose the correct header based on the header name.  
Known headers (`list-unsubscribe`,...) should have their own subclass.
* Improve documentation.

## Examples

### Sending an email with SMTP

See [gmail example](example/send_gmail.dart).

```dart
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

main() async {
  String username = 'username@gmail.com';
  String password = 'password';

  final smtpServer = gmail(username, password);

  // Create our message.
  final message = new Message()
    ..from = new Address(username, 'Your name')
    ..recipients.add('destination@example.com')
    ..ccRecipients.addAll(['destCc1@example.com', 'destCc2@example.com'])
    ..bccRecipients.add(new Address('bccAddress@example.com'))
    ..subject = 'Test Dart Mailer library :: 😀 :: ${new DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>";
  
  final sendReports = await send(message, smtpServer);
}
```

## License
This library is licensed under MIT.
