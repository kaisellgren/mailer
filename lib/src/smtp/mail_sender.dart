import 'dart:async';

import 'package:logging/logging.dart';
import 'package:mailer/src/smtp/validator.dart';

import '../../mailer.dart';
import '../../smtp_server.dart';
import 'connection.dart';
import 'exceptions.dart';
import 'smtp_client.dart' as client;

final Logger _logger = new Logger('mailer_sender');

class _MailSendTask {
  // If [message] is `null` close connection.
  Message message;
  Completer<SendReport> completer;
}

class PersistentConnectionSender {
  Connection _connection;

  final mailSendTasksController = new StreamController<_MailSendTask>();
  Stream<_MailSendTask> get mailSendTasks => mailSendTasksController.stream;

  PersistentConnectionSender(SmtpServer smtpServer, {Duration timeout}) {
    mailSendTasks.listen((_MailSendTask task) async {
      if (_connection == null) {
        _connection = await client.connect(smtpServer, timeout);
      }

      if (task.message == null) {
        try {
          await _connection.close();
          _connection = null;
          task.completer.complete(null);
        } catch (e) {
          _logger.warning('Exception while closing connection', e);
          _connection = null;
          task.completer.completeError(e);
        }
      } else {
        try {
          var report = await _send(task.message, _connection, timeout);
          task.completer.complete(report);
        } catch (e) {
          task.completer.completeError(e);
        }
      }
    });
  }

  /// Throws following exceptions:
  /// [SmtpClientAuthenticationException],
  /// [SmtpUnsecureException],
  /// [SmtpClientCommunicationException],
  /// [SocketException]
  Future<SendReport> send(Message message) {
    var mailTask = _MailSendTask()
      ..message = message
      ..completer = Completer();
    mailSendTasksController.add(mailTask);
    return mailTask.completer.future;
  }

  /// Throws following exceptions:
  /// [SmtpClientAuthenticationException],
  /// [SmtpUnsecureException],
  /// [SmtpClientCommunicationException],
  /// [SocketException]
  Future<void> close() async {
    var closeTask = _MailSendTask()..completer = Completer();
    mailSendTasksController.add(closeTask);
    try {
      await closeTask.completer.future;
    } finally {
      await mailSendTasksController.close();
    }
  }
}

/// Throws following exceptions:
/// [SmtpClientAuthenticationException],
/// [SmtpClientCommunicationException],
/// [SocketException]
/// [SmtpMessageValidationException]
Future<SendReport> send(Message message, SmtpServer smtpServer,
    {Duration timeout}) async {
  _validate(message);
  var connection = await client.connect(smtpServer, timeout);
  var sendReport = _send(message, connection, timeout);
  await client.close(connection);
  return sendReport;
}

/// Convenience method for testing SmtpServer configuration.
///
/// Throws following exceptions if the configuration is incorrect or there is
/// no internet connection:
/// [SmtpClientAuthenticationException],
/// [SmtpClientCommunicationException],
/// [SocketException]
/// others
Future<void> checkCredentials(SmtpServer smtpServer, {Duration timeout}) async {
  var connection = await client.connect(smtpServer, timeout);
  await client.close(connection);
}

/// [SmtpMessageValidationException]
void _validate(Message message) async {
  var validationProblems = validate(message);
  if (validationProblems.isNotEmpty) {
    _logger.severe('Message validation error: '
        '${validationProblems.map((p) => p.msg).join('|')}');
    throw SmtpMessageValidationException(
        'Invalid message.', validationProblems);
  }
}

/// Connection [connection] must already be connected.
/// Throws following exceptions:
/// [SmtpClientCommunicationException],
/// [SocketException]
Future<SendReport> _send(
    Message message, Connection connection, Duration timeout) async {
  DateTime messageSendStart = DateTime.now();
  DateTime messageSendEnd;
  try {
    await client.sendSingleMessage(message, connection, timeout);
    messageSendEnd = DateTime.now();
  } catch (e) {
    _logger.warning('Could not send mail.', e);
    rethrow;
  }
  return SendReport(message, connection.connectionOpenStart, messageSendStart,
      messageSendEnd);
}
