import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:test/test.dart';

SmtpServer? correctSmtpServer;
SmtpServer incorrectCredentials = gmail('mister@gmail.com', 'wrongpass');

void main() async {
  correctSmtpServer = await configureCorrectSmtpServer();

  test('Sending email', () async {
    // TODO: what should be tested here
    //expect(report. != null, true);
  }, skip: true);

  test('SmtpClient.checkCredentials() throws SmtpClientAuthenticationException',
      () async {
    expect(checkCredentials(incorrectCredentials, timeout: const Duration(seconds: 5)),
        throwsA(TypeMatcher<SmtpClientAuthenticationException>()));
  }, skip: false);
}

Future<SmtpServer> configureCorrectSmtpServer() async {
  var config = File('test/smtpserver.json');
  final json = convert.json.decode(await config.readAsString());

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
  return Message()
    ..from = Address(smtpServer.username!)
    ..recipients.add(smtpServer.username)
    ..subject = 'Test Dart Mailer library :: 😀 :: ${DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.';
}
