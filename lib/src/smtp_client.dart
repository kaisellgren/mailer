part of mailer;

class SendReport {
  final Mail mail;
  final bool sent;

  SendReport(this.mail, this.sent);
}

class _ServerMessage {
  final String responseCode;

  /// Every line received from the server is one entry in the message list.
  final List<String> message;

  _ServerMessage(this.responseCode, this.message);
}

class Capabilities {
  final bool startTls;
  final bool authPlain;
  final bool authLogin;
  final List<String> all;

  Capabilities()
      : startTls = false,
        authPlain = true,
        authLogin = false,
        all = const <String>[];

  Capabilities._values(this.startTls, this.authPlain, this.authLogin, this.all);

  factory Capabilities.fromResponse(List<String> ehloMessage) {
    var upperCaseMsg = ehloMessage.map((m) => m.toUpperCase());

    var startTls = upperCaseMsg.contains('STARTTLS');

    var authMethods = upperCaseMsg
        .firstWhere((l) => l.startsWith('AUTH '), orElse: () => 'AUTH')
        .split(' ')
        .skip(1); // first is AUTH
    var plain = authMethods.contains('PLAIN');
    var login = authMethods.contains('LOGIN');

    return new Capabilities._values(startTls, plain, login, ehloMessage);
  }
}

class SmtpClient {
  SmtpOptions _options;

  SmtpClient(this._options);

  Socket _socket;

  StreamQueue<String> _socketIn;

  void _setSocketIn() {
    if (_socketIn != null) {
      _socketIn.cancel();
    }
    _socketIn = new StreamQueue<String>(
        _socket.transform(new Utf8Decoder()).transform(const LineSplitter()));
  }

  /// Initializes a connection to the given server.
  Future<Null> _connect() async {
    _logger
        .finer("Connecting to ${_options.hostName} at port ${_options.port}.");

    // Secured connection was demanded by the user.
    if (_options.secured) {
      _socket = await SecureSocket.connect(_options.hostName, _options.port,
          onBadCertificate: (_) => _options.ignoreBadCertificate);
    } else {
      _socket = await Socket.connect(_options.hostName, _options.port);
    }
    _socket.timeout(const Duration(seconds: 60));

    _setSocketIn();
  }

  /// Returns the next message from server.  An exception is thrown if
  /// [acceptedRespCodes] is not empty and the response code form the server
  /// does not start with any of the strings in [acceptedRespCodes];
  Future<_ServerMessage> _sendAndReceive(String command,
      {List<String> acceptedRespCodes = const ['2'],
      String expect: null,
      bool waitForResponse: true}) async {
    // Send the new command.
    if (command != null) {
      _logger.fine('> $command');
      _socket.write('$command\r\n');
    }

    if (!waitForResponse) {
      // Even though we don't wait for a response, we still wait until the
      // command has been sent.
      await _socket.flush();
      return null;
    }

    final messages = <String>[];
    String responseCode;

    String currentLine;

    // A response from the server always has a space as the 4th character
    // for the _last_ line of a response.
    // Multi-line responses have '-' as 4th character except for the last
    // line.
    while (currentLine == null ||
        (currentLine.length > 3 && currentLine[3] != ' ')) {
      if (!(await _socketIn.hasNext)) {
        throw new SmtpClientCommunicationException(
            "Socket was closed even though a response was expected.");
      }
      currentLine = await _socketIn.next;

      messages.add(currentLine.substring(4));
    }

    responseCode = currentLine.substring(0, 3);

    _logger.fine(messages.map((m) => '< $responseCode $m').join('\n'));

    if (acceptedRespCodes != null &&
        acceptedRespCodes.isNotEmpty &&
        !acceptedRespCodes.any((start) => responseCode.startsWith(start))) {
      var msg =
          'After sending $command, response did not start with any of: $acceptedRespCodes';
      _logger.warning(msg);
      throw new SmtpClientCommunicationException(msg);
    }

    return new _ServerMessage(responseCode, messages);
  }

  /// Returns the capabilities of the server if ehlo was successful.  null if
  /// `helo` is necessary.
  Future<Capabilities> _doEhlo() async {
    var respEhlo =
        await _sendAndReceive('EHLO ${_options.name}', acceptedRespCodes: null);
    if (!respEhlo.responseCode.startsWith('2')) {
      return null;
    }

    var capabilities = new Capabilities.fromResponse(respEhlo.message);

    if (!capabilities.startTls || _socket is SecureSocket) {
      return capabilities;
    }

    // Use a secure socket.  Server announced STARTTLS.
    // The server supports TLS and we haven't switched to it yet,
    // so let's do it.
    var tlsResp = await _sendAndReceive('STARTTLS', acceptedRespCodes: null);
    if (!tlsResp.responseCode.startsWith('2')) {
      // Even though server announced STARTTLS, it now chickens out.
      return null;
    }

    // Replace _socket with an encrypted version.
    await _upgradeConnection();

    // Restart EHLO process.  This time on a secure connection.
    return _doEhlo();
  }

  Future<Capabilities> _doEhloHelo() async {
    var ehlo = await _doEhlo();

    if (ehlo != null) {
      return ehlo;
    }

    // EHLO not accepted.  Let's try HELO.
    await _sendAndReceive('HELO ${_options.name}');
    return new Capabilities();
  }

  /// Upgrades the connection to use TLS.
  Future<Null> _upgradeConnection() async {
    // SecureSocket.secure suggests to call socketSubscription.pause().
    // A StreamQueue always pauses unless we explicitly call next().
    // So we don't need to call pause() ourselves.
    _socket = await SecureSocket.secure(_socket,
        onBadCertificate: (_) => _options.ignoreBadCertificate);
    _setSocketIn();
  }

  Future<Null> _doAuthentication(capabilities) async {
    if (_options.username == null) {
      return;
    }

    if (!capabilities.authLogin) {
      throw new SmtpClientCommunicationException(
          'The server does not support LOGIN authentication method.');
    }

    var username = _options.username;
    var password = _options.password;

    // 'Username:' in base64 is: VXN...
    await _sendAndReceive('AUTH LOGIN',
        acceptedRespCodes: ['334'], expect: 'VXNlcm5hbWU6');
    // 'Password:' in base64 is: UGF...
    await _sendAndReceive(BASE64.encode(username.codeUnits),
        acceptedRespCodes: ['334'], expect: 'UGFzc3dvcmQ6');
    var loginResp = await _sendAndReceive(BASE64.encode(password.codeUnits),
        acceptedRespCodes: []);
    if (!loginResp.responseCode.startsWith('2')) {
      throw new SmtpClientAuthenticationException(
          'Incorrect username ($username) / password');
    }
  }

  Future<SendReport> send(Mail envelope) async {
    await _connect();

    // Greeting (Don't send anything.  We first wait for a 2xx message.)
    await _sendAndReceive(null);

    // EHLO / HELO
    var capabilities = await _doEhloHelo();

    // Authenticate
    await _doAuthentication(capabilities);

    // Tell the server the envelope from address (might be different to the
    // 'From: ' header!
    await _sendAndReceive('MAIL FROM:<${Address.sanitize(envelope.from)}>');

    // Give the server all recipients.
    final allRecipients = [
      envelope.recipients ?? [],
      envelope.ccRecipients ?? [],
      envelope.bccRecipients ?? []
    ].expand((_) => _);
    await Future.forEach(allRecipients, (recipient) async {
      // TODO what if only one address fails?
      await _sendAndReceive('RCPT TO:<${Address.sanitize(recipient)}>');
    });

    // Finally send the actual mail.
    await _sendAndReceive('DATA', acceptedRespCodes: ['2', '3']);

    var content = await envelope.getContents();
    await _sendAndReceive(content, acceptedRespCodes: ['2', '3']);

    await _sendAndReceive('QUIT', waitForResponse: false);

    await _socket.close();
    // TODO close socket.  What about keep-alives?
    //   Then socket should reconnect if disconnected in _connect().

    return new SendReport(envelope, true);
  }
}

abstract class SmtpClientException implements Exception {
  /// A short description of the problem.
  final String message;

  SmtpClientException(this.message);

  @override
  String toString() => message;
}

/// This exception is thrown when the server either doesn't accept
/// the authentication type or the username password is incorrect.
class SmtpClientAuthenticationException extends SmtpClientException {
  SmtpClientAuthenticationException(String message) : super(message);
}

/// This exception is thrown when the server unexpectedly returns a response
/// code which differs to our accepted response codes (usually 2xx).
class SmtpClientCommunicationException extends SmtpClientException {
  SmtpClientCommunicationException(String message) : super(message);
}
