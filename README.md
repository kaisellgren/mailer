# mailer

**mailer** is an easy to use library for composing and sending emails in Dart.

Mailer supports file attachments and HTML emails.

## SMTP definitions

Mailer provides configurations for a few common SMTP servers.

Please create merge requests for missing configurations.

* Copy `lib/smtp_server/gmail.dart` to `lib/smtp_server/xxx.dart`
* Adapt the code.  (See `lib/smtp_server.dart` for possible arguments)
* Export the newly created SMTP server in `lib/smtp_server.dart`
* Create a pull request.

In a lot of cases you will find a configuration
in [legacy.dart](https://github.com/kaisellgren/mailer/blob/v2/lib/legacy.dart)

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
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

main() async {
  String username = 'username@gmail.com';
  String password = 'password';

  final smtpServer = gmail(username, password);
  // Use the SmtpServer class to configure an SMTP server:
  // final smtpServer = SmtpServer('smtp.domain.com');
  // See the named arguments of SmtpServer for further configuration
  // options.  

  // Create our message.
  final message = Message()
    ..from = Address(username, 'Your name')
    ..recipients.add('destination@example.com')
    ..ccRecipients.addAll(['destCc1@example.com', 'destCc2@example.com'])
    ..bccRecipients.add(Address('bccAddress@example.com'))
    ..subject = 'Test Dart Mailer library :: 😀 :: ${DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>";

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
  } on MailerException catch (e) {
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
  // DONE


  // Let's send another message using a slightly different syntax:
  //
  // Addresses without a name part can be set directly.
  // For instance `..recipients.add('destination@example.com')`
  // If you want to display a name part you have to create an
  // Address object: `new Address('destination@example.com', 'Display name part')`
  // Creating and adding an Address object without a name part
  // `new Address('destination@example.com')` is equivalent to
  // adding the mail address as `String`.
  final equivalentMessage = Message()
    ..from = Address(username, 'Your name 😀')
    ..recipients.add(Address('destination@example.com'))
    ..ccRecipients.addAll([Address('destCc1@example.com'), 'destCc2@example.com'])
    ..bccRecipients.add('bccAddress@example.com')
    ..subject = 'Test Dart Mailer library :: 😀 :: ${DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = '<h1>Test</h1>\n<p>Hey! Here is some HTML content</p><img src="cid:myimg@3.141"/>'
    ..attachments = [
      FileAttachment(File('exploits_of_a_mom.png'))
        ..location = Location.inline
        ..cid = '<myimg@3.141>'
    ];

  final sendReport2 = await send(equivalentMessage, smtpServer);

  // Sending multiple messages with the same connection
  //
  // Create a smtp client that will persist the connection
  var connection = PersistentConnection(smtpServer);

  // Send the first message
  await connection.send(message);

  // send the equivalent message
  await connection.send(equivalentMessage);

  // close the connection
  await connection.close();
}
```

## License

This library is licensed under MIT.
