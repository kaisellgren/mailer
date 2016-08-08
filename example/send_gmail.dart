import 'dart:io';

import 'package:mailer/mailer.dart';

/// Test mailer by sending email to yourself
main(List<String> args) {
  if (args.length < 2 || args.length > 3) {
    print('Usage: send_gmail <username> <password> [<file-to-attach>]');
    print('');
    print('If you have Google\'s "app specific passwords" enabled,');
    print('you need to use one of those for the password here.');
    print('');
    exit(1);
  }
  String username = args[0];
  String password = args[1];
  if (username.endsWith('@gmail.com')) {
    username = username.substring(0, username.length - 10);
  }
  File attachFile;
  if (args.length > 2) {
    attachFile = new File(args[2]);
    if (!attachFile.existsSync()) {
      print('Failed to find file to attach: ${attachFile.path}');
      exit(1);
    }
  }

  // If you want to use an arbitrary SMTP server, go with `new SmtpOptions()`.
  // This class below is just for convenience. There are more similar classes available.
  var options = new GmailSmtpOptions()
    ..username = username
    ..password = password;

  // Create our email transport.
  var emailTransport = new SmtpTransport(options);

  // Create our mail/envelope.
  var envelope = new Envelope()
    ..from = '$username@gmail.com'
    ..recipients.add('$username@gmail.com')
    ..subject = 'Test Dart Mailer library :: ${new DateTime.now()}'
    ..text = 'This is the plain text'
    ..html = '<h1>Test</h1><p>Hey! Here\'s some HTML content</p>';
  if (attachFile != null) {
    envelope.attachments.add(new Attachment(file: attachFile));
  }

  // Email it.
  emailTransport
      .send(envelope)
      .then((envelope) => print('Email sent!'))
      .catchError((e) => print('Error occurred: $e'));
}
