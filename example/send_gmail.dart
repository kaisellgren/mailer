import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

/// Test mailer by sending email to yourself
main(List<String> rawArgs) async {
  var args = parseArgs(rawArgs);

  if (args[verboseArg] as bool) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }

  String username = args.rest[0];
  if (username.endsWith('@gmail.com')) {
    username = username.substring(0, username.length - 10);
  }

  List<String> tos = args[toArgs] as List<String> ?? [];
  if (tos.isEmpty)
    tos.add(username.contains('@') ? username : username + '@gmail.com');

  // If you want to use an arbitrary SMTP server, go with `new SmtpServer()`.
  // The gmail function is just for convenience. There are similar functions for
  // other providers.
  final smtpServer = gmail(username, args.rest[1]);

  Iterable<Address> toAd(Iterable<String> addresses) =>
      (addresses ?? <String>[]).map((a) => new Address(a));

  Iterable<Attachment> toAt(Iterable<String> attachments) =>
      (attachments ?? <String>[]).map((a) => new FileAttachment(new File(a)));

  // Create our message.
  final message = new Message()
    ..from = new Address('$username@gmail.com', 'My name 😀')
    ..recipients.addAll(toAd(tos))
    ..ccRecipients.addAll(toAd(args[ccArgs] as Iterable<String>))
    ..bccRecipients.addAll(toAd(args[bccArgs] as Iterable<String>))
    ..subject = 'Test Dart Mailer library :: 😀 :: ${new DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>"
    ..attachments.addAll(toAt(args[attachArgs] as Iterable<String>));

  final sendReports = await send(message, smtpServer);
  sendReports.forEach((sr) {
    if (sr.sent)
      print('Message sent');
    else {
      print('Message not sent.');
      for (var p in sr.validationProblems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  });
}

const toArgs = 'to';
const attachArgs = 'attach';
const ccArgs = 'cc';
const bccArgs = 'bcc';
const verboseArg = 'verbose';

ArgResults parseArgs(List<String> rawArgs) {
  var parser = new ArgParser()
    ..addFlag('verbose', abbr: 'v', help: 'Display logging output.')
    ..addMultiOption(toArgs,
        abbr: 't',
        help: 'The addresses to which the email is sent.\n'
            'If omitted, then the email is sent to the sender.')
    ..addMultiOption(attachArgs,
        abbr: 'a', help: 'Paths to files which will be attached to the email.')
    ..addMultiOption(ccArgs, help: 'The cc addresses for the email.')
    ..addMultiOption(bccArgs, help: 'The bcc addresses for the email.');

  var args = parser.parse(rawArgs);
  if (args.rest.length != 2) {
    showUsage(parser);
    exit(1);
  }

  var attachments = args[attachArgs] as Iterable<String> ?? [];
  for (var f in attachments) {
    File attachFile = new File(f);
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
