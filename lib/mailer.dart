import 'dart:async';

import 'src/entities.dart';
import 'smtp_server.dart';
import 'src/smtp/smtp_client.dart';

export 'src/entities.dart';

Future<List<SendReport>> send(Message message, SmtpServer smtpServer) {
  var client = SmtpClient(smtpServer);
  return client.send(message);
}