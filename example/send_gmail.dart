import 'dart:io';

import 'package:args/args.dart';
import 'package:mailer/mailer.dart';

/// Test mailer by sending email to yourself
main(List<String> rawArgs) {
  var args = parseArgs(rawArgs);
  String username = args.rest[0];
  if (username.endsWith('@gmail.com')) {
    username = username.substring(0, username.length - 10);
  }
  String to = args[TO_ARG] as String;
  if (to == null || to.isEmpty) to = username + '@gmail.com';

  // If you want to use an arbitrary SMTP server, go with `new SmtpOptions()`.
  // This class below is just for convenience. There are more similar classes available.
  var options = new GmailSmtpOptions()
    ..username = username
    ..password = args.rest[1];

  // Create our email transport.
  var emailTransport = new SmtpTransport(options);

  // Create our mail/envelope.
  var envelope = new Envelope()
    ..from = '$username@gmail.com'
    ..recipients.add(to)
    ..subject = 'Test Dart Mailer library :: ${new DateTime.now()}'
    ..text = 'This is the plain text'
    ..html = '<h1>Test</h1><p>Hey! Here\'s some HTML content</p>';
  if (args[CC_ARG] != null) {
    envelope.ccRecipients.add(args[CC_ARG] as String);
  }
  if (args[BCC_ARG] != null) {
    envelope.bccRecipients.add(args[BCC_ARG] as String);
  }
  if (args[ATTACH_ARG] != null) {
    envelope.attachments.add(new Attachment(file: new File(args[ATTACH_ARG] as String)));
  }

  // Email it.
  emailTransport
      .send(envelope)
      .then((envelope) => print('Email sent!'))
      .catchError((e) => print('Error occurred: $e'));
}

const TO_ARG = 'to';
const ATTACH_ARG = 'attach';
const CC_ARG = 'cc';
const BCC_ARG = 'bcc';

ArgResults parseArgs(List<String> rawArgs) {
  var parser = new ArgParser()
    ..addOption(TO_ARG,
        abbr: 't',
        help: 'The address to which the email is sent.\n'
            'If omitted, then the email is sent to the sender.')
    ..addOption(ATTACH_ARG,
        abbr: 'a',
        help: 'Used to specify the path to a file\n'
            'which will be attached to the email.')
    ..addOption(CC_ARG, help: 'The cc address for the email.')
    ..addOption(BCC_ARG, help: 'The bcc address for the email.');

  var args = parser.parse(rawArgs);
  if (args.rest.length != 2) {
    showUsage(parser);
    exit(1);
  }
  if (args[ATTACH_ARG] != null) {
    File attachFile = new File(args[ATTACH_ARG] as String);
    if (!attachFile.existsSync()) {
      showUsage(parser, 'Failed to find file to attach: ${attachFile.path}');
      exit(1);
    }
  }
  return args;
}

showUsage(ArgParser parser, [String message]) {
  if (message != null) {
    print(message);
    print('');
  }
  print('Usage: send_gmail [options] <username> <password>');
  print('');
  print(parser.usage);
  print('');
  print('If you have Google\'s "app specific passwords" enabled,');
  print('you need to use one of those for the password here.');
  print('');
}
