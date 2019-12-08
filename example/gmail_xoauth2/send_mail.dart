import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import "package:googleapis_auth/auth_io.dart";
import "package:http/http.dart" as http;
import 'package:logging/logging.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

const scopes = ['https://mail.google.com'];

main(List<String> rawArgs) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  var args = parseArgs(rawArgs);
  final file = args[argFile] as String;
  final mailTo = args[argTo] as String;

  var jsonCredentials = json.decode(File(file).readAsStringSync());
  var identifier = jsonCredentials['identifier'] as String;
  var secret = jsonCredentials['secret'] as String;
  var refreshToken = jsonCredentials['refreshToken'] as String;
  var username = jsonCredentials['username'] as String;

  var clientId = ClientId(identifier, secret);

  final client = http.Client();
  AccessCredentials credentials = AccessCredentials(
      AccessToken('Bearer', 'EXPIRED', DateTime.utc(2000)),
      refreshToken,
      scopes,
      idToken: identifier);

  // Refresh credentials periodically!
  if (credentials.accessToken == null || credentials.accessToken.hasExpired) {
    credentials = await refreshCredentials(clientId, credentials, client);
  }
  client.close();

  // https://developers.google.com/gmail/imap/xoauth2-protocol
  final oauth2token = base64Encode(utf8.encode(
      'user=$username\x01auth=${credentials.accessToken.type} ${credentials.accessToken.data}\x01\x01'));
  print('OAuth2Token: $oauth2token');

  final smtpClient = gmailXoauth2(oauth2token);
  final message = Message()
    ..from = Address('$username', 'My name 😀')
    ..recipients.add(mailTo)
    ..subject = 'xoauth2'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = "<h1>Test</h1>\n<p>Hey! Here's some HTML content</p>";

  final report = await send(message, smtpClient);
  print('Message sent. $report');
}

const argTo = 'to';
const argFile = 'file';

ArgResults parseArgs(List<String> rawArgs) {
  var parser = ArgParser()
    ..addOption(argTo, help: 'Send test mail to this address.')
    ..addOption(argFile, help: 'Read secrets from <file>.');

  var argResults = parser.parse(rawArgs);
  var toAddress = argResults[argTo] as String;
  var file = argResults[argFile] as String;
  if (toAddress == null || toAddress.isEmpty || file == null || file.isEmpty) {
    print(parser.usage);
    throw new Exception('Missing argument');
  }
  return argResults;
}
