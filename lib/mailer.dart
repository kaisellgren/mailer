import 'dart:async';

import 'smtp_server.dart';

import 'src/entities.dart';
import 'src/smtp/smtp_client.dart';

export 'src/entities.dart';
export 'legacy.dart';

/// Throws following exceptions if [catchExceptions] is false:
/// [SmtpClientAuthenticationException],
/// [SmtpClientCommunicationException],
/// [SmtpUnsecureException],
/// [SmtpMessageValidationException],
/// [SocketException]    // Connection dropped
/// Please report other exceptions you encounter.
Future<List<SendReport>> send(Message message, SmtpServer smtpServer,
    {bool catchExceptions, Duration timeout}) {
  var client = new SmtpClient(smtpServer);
  return client.send(message,
      catchExceptions: catchExceptions, timeout: timeout);
}
