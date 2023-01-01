import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Test mailer by sending email to yourself
void main(List<String> rawArgs) async {
  var args = parseArgs(rawArgs);

  if (args[verboseArg] as bool) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
  }

  var username = args.rest[0];
  if (username.endsWith('@gmail.com')) {
    username = username.substring(0, username.length - 10);
  }

  var tos = args[toArgs] as List<String>? ?? [];
  if (tos.isEmpty) {
    tos.add(username.contains('@') ? username : '$username@gmail.com');
  }

  // If you want to use an arbitrary SMTP server, go with `SmtpServer()`.
  // The gmail function is just for convenience. There are similar functions for
  // other providers.
  final smtpServer = gmail(username, args.rest[1]);

  Iterable<Address> toAd(Iterable<String>? addresses) =>
      (addresses ?? []).map((a) => Address(a));

  Iterable<Attachment> toAt(Iterable<String>? attachments) =>
      (attachments ?? []).map((a) => FileAttachment(File(a)));

  // Create our message.
  final message = Message()
    ..from = Address('$username@gmail.com', 'My name 😀')
    ..recipients.addAll(toAd(tos))
    ..ccRecipients.addAll(toAd(args[ccArgs] as Iterable<String>?))
    ..bccRecipients.addAll(toAd(args[bccArgs] as Iterable<String>?))
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>"
    ..attachments.addAll(toAt(args[attachArgs] as Iterable<String>?));

  try {
    final sendReport =
        await send(message, smtpServer, timeout: Duration(seconds: 15));
    print('Message sent: $sendReport');
  } on MailerException catch (e) {
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }

  print('Now sending using a persistent connection');
  var connection =
      PersistentConnection(smtpServer, timeout: Duration(seconds: 15));
  // Send multiple mails on one connection:
  try {
    for (var i = 0; i < 3; i++) {
      message.subject =
          'Test Dart Mailer library :: 😀 :: ${DateTime.now()} / $i';
      final sendReport = await connection.send(message);
      print('Message sent: $sendReport');
    }
  } on MailerException catch (e) {
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  } catch (e) {
    print('Other exception: $e');
  } finally {
    await connection.close();
  }
}

const toArgs = 'to';
const attachArgs = 'attach';
const ccArgs = 'cc';
const bccArgs = 'bcc';
const verboseArg = 'verbose';

ArgResults parseArgs(List<String> rawArgs) {
  var parser = ArgParser()
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

  var attachments = args[attachArgs] as Iterable<String>? ?? [];
  for (var f in attachments) {
    var attachFile = File(f);
    if (!attachFile.existsSync()) {
      showUsage(parser, 'Failed to find file to attach: ${attachFile.path}');
      exit(1);
    }
  }
  return args;
}

void showUsage(ArgParser parser, [String? message]) {
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
