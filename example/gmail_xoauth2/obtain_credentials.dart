import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

const scopes = ['https://mail.google.com'];

// ignore: always_declare_return_types
main(List<String> rawArgs) async {
  var args = parseArgs(rawArgs);
  final identifier = args[argId] as String;
  final secret = args[argSecret] as String?;
  final username = args[argUsername] as String?;

  final clientId = ClientId(identifier, secret);
  final fileName = args[argFile] as String?;

  AccessCredentials credentials;
  final client = http.Client();
  credentials = await obtainAccessCredentialsViaUserConsent(
      clientId, scopes, client, prompt);
  client.close();

  print('Access token data: ${credentials.accessToken.data}');
  print('Access token type: ${credentials.accessToken.type}');
  print('Access token expiry: ${credentials.accessToken.expiry}');
  print('Credentials ID token: ${credentials.idToken}');
  print('Credentials refresh token: ${credentials.refreshToken}');
  print('Credentials scopes: ${credentials.scopes.join(',')}');
  if (fileName != null && fileName.isNotEmpty) {
    print('');
    print('I will now store the refresh token and the identifier in $fileName');
    var file = File(fileName);
    file.writeAsStringSync('''
        {
          "identifier": "$identifier",
          "secret": "$secret",
          "refreshToken": "${credentials.refreshToken}",
          "username": "$username"
        }''');
  }
}

void prompt(String url) {
  print('Please go to the following URL and grant access:');
  print('  => $url');
  print('');
}

const argId = 'id';
const argSecret = 'secret';
const argFile = 'file';
const argUsername = 'username';

ArgResults parseArgs(List<String> rawArgs) {
  var parser = ArgParser()
    ..addOption(argId,
        help:
            'The app-id from your credentials (https://console.developers.google.com/apis).')
    ..addOption(argSecret,
        help:
            'The app-secret from your credentials (https://console.developers.google.com/apis).')
    ..addOption(argUsername,
        help:
            'The mail address which gives the app-id the permission to read/send mails.')
    ..addOption(argFile, help: 'Write secrets to <file>.');

  var argResults = parser.parse(rawArgs);
  var id = argResults[argId] as String?;
  var secret = argResults[argSecret] as String?;
  var username = argResults[argUsername] as String?;
  if (id == null ||
      id.isEmpty ||
      secret == null ||
      secret.isEmpty ||
      username == null ||
      username.isEmpty) {
    print(parser.usage);
    throw Exception('Missing argument');
  }
  return argResults;
}
