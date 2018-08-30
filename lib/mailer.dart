import 'dart:async';

import 'smtp_server.dart';

import 'src/entities.dart';
import 'src/smtp/smtp_client.dart';

export 'src/entities.dart';
export 'legacy.dart';

Future<List<SendReport>> send(Message message, SmtpServer smtpServer) {
  var client = SmtpClient(smtpServer);
  return client.send(message);
}