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

## TODO

* All possible SMTP authentication methods (now just LOGIN)
* Sendmail
* Stream attachments
* String-based attachments

## Examples

### Sending an email with SMTP

In this example we send an email using a Gmail account.
```dart
import 'package:mailer/mailer.dart';

main() {
  // If you want to use an arbitrary SMTP server, go with `new SmtpOptions()`.
  // This class below is just for convenience. There are more similar classes available.
  var options = new GmailSmtpOptions()
    ..username = 'your gmail username'
    ..password = 'your gmail password'; // Note: if you have Google's "app specific passwords" enabled,
                                        // you need to use one of those here.

  // Create our email transport.
  var emailTransport = new SmtpTransport(options);

  // Create our mail/envelope.
  var envelope = new Envelope()
    ..from = 'foo@bar.com'
    ..recipients.add('someone@somewhere.com')
    ..subject = 'Testing the Dart Mailer library 語'
    ..attachments.add(new Attachment(file: new File('path/to/file')))
    ..text = 'This is a cool email message. Whats up? 語'
    ..html = '<h1>Test</h1><p>Hey!</p>';

  // Email it.
  emailTransport.send(envelope)
    .then((success) => print('Email sent! $success'))
    .catchError((e) => print('Error occured: $e'));
}
```

## License
This library is licensed under MIT.
