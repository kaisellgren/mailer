import 'dart:async';
import 'dart:convert' as JSON;
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mailer/src/smtp/smtp_client.dart';
import "package:test/test.dart";

SmtpServer correctSmtpServer;
SmtpServer incorrectCredentials = gmail("mister@gmail.com", "wrongpass");

void main() async {
  correctSmtpServer = await configureCorrectSmtpServer();

  test('Sending email', () async {

    List<SendReport> reports = await send(createMessage(correctSmtpServer),
                                          correctSmtpServer,
                                          timeout: Duration(seconds: 10));
    expect(reports.last.sent, true);
  }, skip: true);

  test('SmtpClient.checkCredentials() throws SmtpClientAuthenticationException', () async {
    SmtpClient smtpClient = SmtpClient(incorrectCredentials);
    expect(smtpClient.checkCredentials(timeout: const Duration(seconds: 5)),
           throwsA(TypeMatcher<SmtpClientAuthenticationException>()));

  }, skip: false);

}

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

Message createMessage(SmtpServer smtpServer) {
  // Message to myself
  return new Message()
    ..from = new Address(smtpServer.username)
    ..recipients.add(smtpServer.username)
    ..subject = 'Test Dart Mailer library :: 😀 :: ${new DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.';
}
