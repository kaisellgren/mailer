import 'dart:io';

import 'package:mailer/mailer.dart';

/// Test mailer by sending email to yourself
main(List<String> args) {
  if (args.length != 2) {
    print('Usage: send_gmail <gmail_username> <gmail_password>');
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
    ..subject = 'Testing the Dart Mailer library'
    ..text = 'This is the plain text'
    ..html = '<h1>Test</h1><p>Hey! Here\'s some HTML content</p>';

  // Email it.
  emailTransport
      .send(envelope)
      .then((envelope) => print('Email sent!'))
      .catchError((e) => print('Error occurred: $e'));
}
