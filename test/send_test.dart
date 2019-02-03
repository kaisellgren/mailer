import 'dart:io';
import 'dart:async';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import "package:test/test.dart";
import 'dart:convert' as JSON;


Future<SmtpServer> configureCorrectSmtpServer() async {
  var config = File('test/smtpserver.json');
  final json = JSON.jsonDecode(await config.readAsString());

  return SmtpServer(
    json['host'] as String,
    username: json['username'] as String,
    password: json['password'] as String,
    port: json['port'] as int,
    ssl: json['ssl'] as bool,
    allowInsecure: json['allowInsecure'] as bool,
  );
}

Message createMessage(SmtpServer smtpServer, int number) {
  // Message to myself
  return new Message()
    ..from = new Address(smtpServer.username)
    ..recipients.add(smtpServer.username)
    ..subject = 'Test[$number] Dart Mailer library :: 😀 :: ${new DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.';
}

void main() async {
  final SmtpServer correctSmtpServer = await configureCorrectSmtpServer();

  test('Sending email', () async {

    List<SendReport> reports = await send(createMessage(correctSmtpServer, 1),
                                          correctSmtpServer,
                                          timeout: Duration(seconds: 10));
    expect(reports.last.sent, true);
  });

}