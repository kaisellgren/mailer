# mailer

**mailer** is an easy-to-use library for composing and sending emails in Dart.

It supports:
*   **Plaintext and HTML** emails.
*   **Attachments** (files, streams, etc.).
*   **Inline images** (using CID).
*   **Unicode** support.
*   **RFC 3030** (CHUNKING) for efficient large file transfer.
*   **Secure connections** (TLS/SSL) with context-aware sanitization.
*   **Custom Address Validation** strategies (strict, permissive, etc.).
*   **Pre-configured services** (Gmail, Yahoo, Hotmail, etc.) and generic SMTP support.

## Usage

### Simple Example (Gmail)

```dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() async {
  String username = 'username@gmail.com';
  String password = 'password'; // Use an App Password if 2FA is enabled

  final smtpServer = gmail(username, password);
  // Use the SmtpServer class to configure any other SMTP server:
  // final smtpServer = SmtpServer('smtp.domain.com');

  final message = Message()
    ..from = Address(username, 'Your Name')
    ..recipients.add('destination@example.com')
    ..ccRecipients.addAll(['destCc1@example.com', 'destCc2@example.com'])
    ..bccRecipients.add(Address('bccAddress@example.com'))
    ..subject = 'Test Dart Mailer library :: 😀 :: ${DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>";

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: $sendReport');
  } on MailerException catch (e) {
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
}
```

### Advanced Usage

#### Attachments and Inline Images

```dart
final message = Message()
  ..from = Address(username, 'Your Name')
  ..recipients.add('destination@example.com')
  ..subject = 'Inline Image Test'
  ..html = '<h1>Test</h1><p>Here is an image:</p><img src="cid:myimg@3.141"/>'
  ..attachments = [
    FileAttachment(File('image.png'))
      ..location = Location.inline
      ..cid = '<myimg@3.141>'
  ];
```

#### Custom Address Validation

The library validates addresses before sending. By default, it uses a simple check (contains `@` with non-empty parts). You can customize this behavior:

**Available validators:**
| Validator | Use Case |
|:----------|:---------|
| `PracticalAddressValidator` | **Recommended for input validation.** Rejects IP literals, quoted strings, and domains without dots. |
| `StrictAddressValidator` | Full RFC 5322 compliance. Accepts technically valid but uncommon formats. |
| `PermissiveAddressValidator` | Accepts any non-empty string. |

**Validating user input (recommended):**
```dart
import 'package:mailer/src/core/address_validator.dart';

final validator = PracticalAddressValidator();
final address = Address('test@example.com');

if (validator.validate(address)) {
  print('Address is valid');
} else {
  print('Address is invalid - may not be deliverable');
}
```

**Using a validator for sending:**
```dart
final message = Message()
  ..validator = StrictAddressValidator() // or PracticalAddressValidator()
  ..from = 'valid@example.com';
```

#### Persistent Connection

For sending multiple messages efficiently, use `PersistentConnection`.

```dart
var connection = PersistentConnection(smtpServer);

await connection.send(message1);
await connection.send(message2);

await connection.close();
```


## Documentation

*   [Using Inline Images (doc/inline_image_guide.md)](doc/inline_image_guide.md)
*   [Gmail XOAUTH2 Guide (doc/gmail_xoauth2/README.md)](doc/gmail_xoauth2/README.md)

## Tutorials

### Flutter Developers

**Flutter Web is NOT supported.** Sending emails via SMTP directly from a browser is technically impossible due to security restrictions (CORS, lack of raw socket access). You must use a backend server or a proxy.

**Security Warning:** Do NOT embed your SMTP credentials (username/password) directly in your client-side Flutter code. If you do, anyone can extract them and use your account to send spam.

[Johannes Milke](https://github.com/JohannesMilke) has created an excellent tutorial on how to use `mailer` without needing to embed your credentials in the Flutter app:

*   [Flutter Tutorial - How To Send Email In Background [2021] Without Backend](https://www.youtube.com/watch?v=RDwst9icjAY)

The tutorial uses Firebase and requests the credentials of the Android user, avoiding storing your credentials in the app.

### Server Developers

[Suragch](https://suragch.medium.com/) has written an excellent tutorial on [How to send yourself email notifications from a Dart server](https://suragch.medium.com/how-to-send-yourself-email-notifications-from-a-dart-server-a7c16a1900d6).

---

If you have created a tutorial yourself (or know of one) please open an issue, so it can be added to this list. Note that tutorials don't need to be in English!

## Logging

The library uses the `logging` package. By default, no logs are output.
To see the SMTP communication (which is helpful for debugging), configure a logger listener:

```dart
import 'package:logging/logging.dart';

void main() {
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  // ... rest of your code
}
```

**Security Note:** Credentials (passwords, tokens) in `AUTH` commands are masked (`*******`) in the logs to prevent accidental leakage.

## FAQ

**Q: How do I handle large attachments?**
A: `mailer` supports RFC 3030 (CHUNKING). If the server supports it, `mailer` will automatically stream the data using `BDAT` commands, which is more efficient than the standard `DATA` command.

**Q: How do I use Gmail with 2FA?**
A: You must generate an **App Password** in your Google Account settings and use that instead of your standard password.

## License

MIT
