import 'dart:async';
import 'dart:convert';
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
  final Connection _c;
  final SmtpServer  _smtpServer;

  SmtpClient(this._smtpServer) : _c = new Connection(_smtpServer);

  /// Returns the capabilities of the server if ehlo was successful.  null if
  /// `helo` is necessary.
  Future<Capabilities> _doEhlo() async {
    var respEhlo =
        await _c.send('EHLO ${_smtpServer.name}', acceptedRespCodes: null);

    if (!respEhlo.responseCode.startsWith('2')) {
      return null;
    }

    var capabilities = new Capabilities.fromResponse(respEhlo.responseLines);

    if (!capabilities.startTls || _c.isSecure) {
      return capabilities;
    }

    // Use a secure socket.  Server announced STARTTLS.
    // The server supports TLS and we haven't switched to it yet,
    // so let's do it.
    var tlsResp = await _c.send('STARTTLS', acceptedRespCodes: null);
    if (!tlsResp.responseCode.startsWith('2')) {
      // Even though server announced STARTTLS, it now chickens out.
      return null;
    }

    // Replace _socket with an encrypted version.
    await _c.upgradeConnection();

    // Restart EHLO process.  This time on a secure connection.
    return _doEhlo();
  }

  Future<Capabilities> _doEhloHelo() async {
    var ehlo = await _doEhlo();

    if (ehlo != null) {
      return ehlo;
    }

    // EHLO not accepted.  Let's try HELO.
    await _c.send('HELO ${_smtpServer.name}');
    return new Capabilities();
  }

  Future<Null> _doAuthentication(Capabilities capabilities) async {
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
    await _c.send('AUTH LOGIN',
        acceptedRespCodes: ['334'], expect: 'VXNlcm5hbWU6');
    // 'Password:' in base64 is: UGF...
    await _c.send(base64.encode(username.codeUnits),
        acceptedRespCodes: ['334'], expect: 'UGFzc3dvcmQ6');
    var loginResp =
        await _c.send(base64.encode(password.codeUnits), acceptedRespCodes: []);
    if (!loginResp.responseCode.startsWith('2')) {
      throw new SmtpClientAuthenticationException(
          'Incorrect username ($username) / password');
    }
  }

  Future<List<SendReport>> send(Message message) async {
    final List<SendReport> sendReports = [];

    // Don't even try to connect to the server, if message-validation fails.
    var problems = validate(message);
    if (problems.isNotEmpty) {
      sendReports
          .add(new SendReport(message, false, validationProblems: problems));
      return sendReports;
    }

    try {
      await _c.connect();

      // Greeting (Don't send anything.  We first wait for a 2xx message.)
      await _c.send(null);

      // EHLO / HELO
      var capabilities = await _doEhloHelo();

      _c.verifySecuredConnection();

      // Authenticate
      await _doAuthentication(capabilities);

      var irMessage = IRMessage(message);

      List<String> envelopeTos = irMessage.envelopeTos;

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

      await _c.send('MAIL FROM:<${irMessage.envelopeFrom}>');

      // Give the server all recipients.
      // TODO what if only one address fails?
      await Future.forEach(
          envelopeTos, (recipient) => _c.send('RCPT TO:<$recipient>'));

      // Finally send the actual mail.
      await _c.send('DATA', acceptedRespCodes: ['2', '3']);

      await _c.sendStream(irMessage.data(capabilities));

      await _c.send(null, acceptedRespCodes: ['2', '3']);

      await _c.close();

      // TODO What about keep-alives?
      //   Then socket should reconnect if disconnected in _connect().

      sendReports.add(new SendReport(message, true));
    } catch (exception) {
      sendReports.add(new SendReport(message, false, validationProblems: [
        new Problem('UNKNOWN', 'Received an exception: $exception')
      ]));
    }

    await _c.send('QUIT', waitForResponse: false);
    return sendReports;
  }
}
