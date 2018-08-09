import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:logging/logging.dart';
import '../entities/address.dart';
import '../entities/mail.dart';
import '../entities/send_report.dart';
import '../smtp_options.dart';
import 'connection.dart';
import 'capabilities.dart';
import 'exceptions.dart';
import 'package:mailer/src/entities/problem.dart';
import 'validator.dart';

final Logger _logger = new Logger('smtp-client');

class SmtpClient {
  final Connection _connection;
  final SmtpOptions smtpOptions;
  final Queue<Mail> _mails = new Queue<Mail>();

  SmtpClient(this.smtpOptions) : _connection = new Connection(smtpOptions);

  /// Returns the capabilities of the server if ehlo was successful.  null if
  /// `helo` is necessary.
  Future<Capabilities> _doEhlo() async {
    var respEhlo = await _connection.sendAndReceive('EHLO ${smtpOptions.name}',
        acceptedRespCodes: null);

    if (!respEhlo.responseCode.startsWith('2')) {
      return null;
    }

    var capabilities = new Capabilities.fromResponse(respEhlo.responseLines);

    if (!capabilities.startTls || _connection.isSecure) {
      return capabilities;
    }

    // Use a secure socket.  Server announced STARTTLS.
    // The server supports TLS and we haven't switched to it yet,
    // so let's do it.
    var tlsResp =
    await _connection.sendAndReceive('STARTTLS', acceptedRespCodes: null);
    if (!tlsResp.responseCode.startsWith('2')) {
      // Even though server announced STARTTLS, it now chickens out.
      return null;
    }

    // Replace _socket with an encrypted version.
    await _connection.upgradeConnection();

    // Restart EHLO process.  This time on a secure connection.
    return _doEhlo();
  }

  Future<Capabilities> _doEhloHelo() async {
    var ehlo = await _doEhlo();

    if (ehlo != null) {
      return ehlo;
    }

    // EHLO not accepted.  Let's try HELO.
    await _connection.sendAndReceive('HELO ${smtpOptions.name}');
    return new Capabilities();
  }

  Future<Null> _doAuthentication(Capabilities capabilities) async {
    if (smtpOptions.username == null) {
      return;
    }

    if (!capabilities.authLogin) {
      throw new SmtpClientCommunicationException(
          'The server does not support LOGIN authentication method.');
    }

    var username = smtpOptions.username;
    var password = smtpOptions.password;

    // 'Username:' in base64 is: VXN...
    await _connection.sendAndReceive('AUTH LOGIN',
        acceptedRespCodes: ['334'], expect: 'VXNlcm5hbWU6');
    // 'Password:' in base64 is: UGF...
    await _connection.sendAndReceive(BASE64.encode(username.codeUnits),
        acceptedRespCodes: ['334'], expect: 'UGFzc3dvcmQ6');
    var loginResp = await _connection.sendAndReceive(
        BASE64.encode(password.codeUnits),
        acceptedRespCodes: []);
    if (!loginResp.responseCode.startsWith('2')) {
      throw new SmtpClientAuthenticationException(
          'Incorrect username ($username) / password');
    }
  }

  Future<SendReport> send() async {
    await _connection.connect();

    // Greeting (Don't send anything.  We first wait for a 2xx message.)
    await _connection.sendAndReceive(null);

    // EHLO / HELO
    var capabilities = await _doEhloHelo();

    _connection.verifySecuredConnection();

    // Authenticate
    await _doAuthentication(capabilities);

    final List<SendReport>sendReports = [];
    while (_mails.isNotEmpty) {
      final mail = _mails.removeFirst();
      if (mail == null) continue;
      try {
        var problems = validate(mail);
        if (problems.isNotEmpty) {
          sendReports.add(
              new SendReport(mail, false, validationProblems: problems));
          continue;
        }

        // All recipients.
        List<String> envelopeTos = mail.envelopeTos ?? <String>[];
        if (envelopeTos.isEmpty) {
          envelopeTos = [
            mail.recipients ?? [],
            mail.ccRecipients ?? [],
            mail.bccRecipients ?? []
          ]
              .expand((_) => _)
              .where(((a) => a?.mailAddress != null)).toList(growable: false);
        }

        if (envelopeTos.isEmpty) {
          _logger.info('Mail without recipients.  Not sending. ($mail)');
          sendReports.add(new SendReport(mail, false, validationProblems: [
            new Problem('NO_RECIPIENTS', 'Mail does not have any recipients.')
          ]));
          continue;
        }

        // Make sure that the server knows, that we are sending a new mail.
        // This also allows us to simply `continue;` to the next mail in case
        // something goes wrong.
        await _connection.sendAndReceive('RSET');

        // Tell the server the envelope from address (might be different to the
        // 'From: ' header!
        final envelopeFrom = mail.envelopeFrom ?? mail.from?.mailAddress ?? '';
        await _connection.sendAndReceive('MAIL FROM:<$envelopeFrom>');

        // Give the server all recipients.
        // TODO what if only one address fails?
        await Future.forEach(envelopeTos, (recipient) =>
            _connection.sendAndReceive('RCPT TO:<$recipient>'));

        // Finally send the actual mail.
        await _connection.sendAndReceive('DATA', acceptedRespCodes: ['2', '3']);

        var content = await envelope.getContents();
        await _connection.sendAndReceive(
            content, acceptedRespCodes: ['2', '3']);

        await _socket.close();
        // TODO close socket.  What about keep-alives?
        //   Then socket should reconnect if disconnected in _connect().

        sendReports.add(new SendReport(mail, true));
      } catch (exception) {
        sendReports.add(new SendReport(mail, false, validationProblems: [
          new Problem('UNKNOWN', 'Received an exception: $exception')]));
      }
    }
    await _connection.sendAndReceive('QUIT', waitForResponse: false);
    return sendReports;
  }
}
