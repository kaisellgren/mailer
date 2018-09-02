import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart2_constant/convert.dart' as convert;
import 'package:mailer/mailer.dart';
import 'package:mailer/src/smtp/capabilities.dart';
import 'package:mailer/src/smtp/internal_representation/internal_representation.dart';

/// Test mailer by sending email to yourself
main(List<String> rawArgs) async {
  var args = parseArgs(rawArgs);

  String username = args.rest[0];
  if (username.endsWith('@gmail.com')) {
    username = username.substring(0, username.length - 10);
  }

  List<String> tos = args[toArgs] as List<String> ?? [];
  if (tos.isEmpty)
    tos.add(username.contains('@') ? username : username + '@gmail.com');

  Iterable<Address> toAd(Iterable<String> addresses) =>
      (addresses ?? <String>[]).map((a) => new Address(a, 'some name'));

  Iterable<Attachment> toAt(Iterable<String> attachments) =>
      (attachments ?? <String>[]).map((a) => new FileAttachment(new File(a)));

  // Create our message.
  final message = new Message()
    ..from = new Address('$username@gmail.com')
    ..recipients.addAll(toAd(tos))
    ..ccRecipients.addAll(args[ccArgs] as Iterable<dynamic>)
    ..bccRecipients.addAll(args[bccArgs] as Iterable<dynamic>)
    ..subject =
        'Test Dart Mailer library :: 😀 :: ${new DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>"
    ..attachments.addAll(toAt(args[attachArgs] as Iterable<String>))
  ;

  var irMessage = new IRMessage(message);
  const capabilities = const Capabilities();
  var data = irMessage.data(capabilities);

  var streamDone = new Completer();
  print('DATA');
  data.listen((d) => stdout.write(convert.utf8.decode(d))).onDone(() => streamDone.complete());
  await streamDone.future;
  print('-- DATA DONE --');
}

const toArgs = 'to';
const attachArgs = 'attach';
const ccArgs = 'cc';
const bccArgs = 'bcc';

ArgResults parseArgs(List<String> rawArgs) {
  var parser = new ArgParser()
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
