import 'dart:async';
import 'package:dart2_constant/convert.dart' as convert;
import 'package:logging/logging.dart';
import 'package:mailer/smtp_server.dart';
import 'internal_representation/internal_representation.dart';
import '../entities/message.dart';
import '../entities/send_report.dart';
import 'connection.dart';
import 'capabilities.dart';
import 'exceptions.dart';
import 'package:mailer/src/entities/problem.dart';
import 'validator.dart';

final Logger _logger = new Logger('smtp-client');

class SmtpClient {
  final SmtpServer _smtpServer;

  SmtpClient(this._smtpServer);

  /// Returns the capabilities of the server if ehlo was successful.  null if
  /// `helo` is necessary.
  Future<Capabilities> _doEhlo(Connection c) async {
    var respEhlo =
    await c.send('EHLO ${_smtpServer.name}', acceptedRespCodes: null);

    if (!respEhlo.responseCode.startsWith('2')) {
      return null;
    }

    var capabilities = new Capabilities.fromResponse(respEhlo.responseLines);

    if (!capabilities.startTls || c.isSecure) {
      return capabilities;
    }

    // Use a secure socket.  Server announced STARTTLS.
    // The server supports TLS and we haven't switched to it yet,
    // so let's do it.
    var tlsResp = await c.send('STARTTLS', acceptedRespCodes: null);
    if (!tlsResp.responseCode.startsWith('2')) {
      // Even though server announced STARTTLS, it now chickens out.
      return null;
    }

    // Replace _socket with an encrypted version.
    await c.upgradeConnection();

    // Restart EHLO process.  This time on a secure connection.
    return _doEhlo(c);
  }

  Future<Capabilities> _doEhloHelo(Connection c) async {
    var ehlo = await _doEhlo(c);

    if (ehlo != null) {
      return ehlo;
    }

    // EHLO not accepted.  Let's try HELO.
    await c.send('HELO ${_smtpServer.name}');
    return new Capabilities();
  }

  Future<Null> _doAuthentication(Connection c, Capabilities capabilities) async {
    if (_smtpServer.username == null) {
      return;
    }

    if (!capabilities.authLogin) {
      throw new SmtpClientCommunicationException(
          'The server does not support LOGIN authentication method.');
    }

    var username = _smtpServer.username;
    var password = _smtpServer.password;

    // 'Username:' in base64 is: VXN...
    await c.send('AUTH LOGIN',
        acceptedRespCodes: ['334'], expect: 'VXNlcm5hbWU6');
    // 'Password:' in base64 is: UGF...
    await c.send(convert.base64.encode(username.codeUnits),
        acceptedRespCodes: ['334'], expect: 'UGFzc3dvcmQ6');
    var loginResp = await c
        .send(convert.base64.encode(password.codeUnits), acceptedRespCodes: []);
    if (!loginResp.responseCode.startsWith('2')) {
      throw new SmtpClientAuthenticationException(
          'Incorrect username ($username) / password');
    }
  }

  Future<List<SendReport>> send(Message message,
      {Duration timeout = const Duration(seconds: 60)}) async {

    final List<SendReport> sendReports = [];
    final Connection c = new Connection(_smtpServer, timeout: timeout);

    // Don't even try to connect to the server, if message-validation fails.
    var problems = validate(message);
    if (problems.isNotEmpty) {
      sendReports
          .add(new SendReport(message, false, validationProblems: problems));
      return sendReports;
    }

    IRMessage irMessage;
    try {
      // Constructor might throw IRProblemException.
      irMessage = new IRMessage(message);
    } on IRProblemException catch (e) {
      sendReports
          .add(new SendReport(message, false, validationProblems: [e.problem]));
      return sendReports;
    }

    try {
      await c.connect();

      // Greeting (Don't send anything.  We first wait for a 2xx message.)
      await c.send(null);

      // EHLO / HELO
      var capabilities = await _doEhloHelo(c);

      c.verifySecuredConnection();

      // Authenticate
      await _doAuthentication(c, capabilities);

      Iterable<String> envelopeTos = irMessage.envelopeTos;

      if (envelopeTos.isEmpty) {
        _logger.info('Mail without recipients.  Not sending. ($message)');
        sendReports.add(new SendReport(message, false, validationProblems: [
          new Problem('NO_RECIPIENTS', 'Mail does not have any recipients.')
        ]));
        return sendReports;
      }

      // Make sure that the server knows, that we are sending a new mail.
      // This also allows us to simply `continue;` to the next mail in case
      // something goes wrong.
      // await _c.send('RSET');  // We currently reconnect for every msg.

      // Tell the server the envelope from address (might be different to the
      // 'From: ' header!)

      bool smtputf8 = capabilities.smtpUtf8;
      await c.send(
          'MAIL FROM:<${irMessage.envelopeFrom}> ${smtputf8
              ? ' SMTPUTF8'
              : ''}');

      // Give the server all recipients.
      // TODO what if only one address fails?
      await Future.forEach(
          envelopeTos, (recipient) => c.send('RCPT TO:<$recipient>'));

      // Finally send the actual mail.
      await c.send('DATA', acceptedRespCodes: ['2', '3']);

      await c.sendStream(irMessage.data(capabilities));

      await c.send('.', acceptedRespCodes: ['2', '3']);

      await c.send('QUIT', waitForResponse: false);

      sendReports.add(new SendReport(message, true));
    } catch (exception) {
      sendReports.add(new SendReport(message, false, validationProblems: [
        new Problem('UNKNOWN', 'Received an exception: $exception')
      ]));
    } finally {
      await c.close();
    }

    return sendReports;
  }
}
