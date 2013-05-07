part of mailer;

typedef void SmtpResponseAction(String message);

/**
 * An SMTP client for sending out emails.
 */
class SmtpClient {
  SmtpOptions options;

  /**
   * A function to run if some data arrives from the server.
   */
  SmtpResponseAction _currentAction;

  bool _ignoreData = false;

  Socket _connection;

  bool _connectionOpen = false;

  /**
   * A list of supported authentication protocols.
   */
  List<String> supportedAuthentications = [];

  /**
   * When the connection is idling, it's reasy to take in a new message.
   */
  Stream onIdle;
  StreamController _onIdleController = new StreamController();

  /**
   * This stream emits whenever an email has been sent.
   *
   * The returned object is an [Envelope] containing the details of what has been emailed.
   */
  Stream<Envelope> onSend;
  StreamController _onSendController = new StreamController();

  /**
   * Sometimes the response comes in pieces. We store each piece here.
   */
  List<int> _remainder = [];

  Envelope _envelope;

  SmtpClient(this.options) {
    onIdle = _onIdleController.stream.asBroadcastStream();
    onSend = _onSendController.stream.asBroadcastStream();
  }

  /**
   * Initializes a connection to the given server.
   */
  Future _connect({secured: false}) {
    var completer = new Completer(), future;

    if (secured || options.secured) {
      future = SecureSocket.connect(options.hostName, options.port);
    } else {
      future = Socket.connect(options.hostName, options.port);
    }

    future.then((socket) {
      _connectionOpen = true;

      _connection = socket;
      _connection.listen(_onData, onError: (e) => _logger.severe('Error occured with the connection to the SMTP server: $e'));
      _connection.done.then((_) => _connectionOpen = false);

      completer.complete(true);
    }).catchError((e) => completer.completeError('Error connecting to the SMTP server: $e'));

    return completer.future;
  }

  /**
   * Sends out an email.
   */
  void send(Envelope envelope) {
    _envelope = envelope;

    _connect().then((_) => _currentAction = _actionGreeting);

    new Timer(const Duration(seconds: 3), () => _connection.close());

    onIdle.listen((_) {
      _currentAction = _actionMail;
      sendCommand('MAIL FROM:<${_sanitizeEmail(_envelope.from)}>');
    });
  }

  /**
   * Sends a command to the SMTP server.
   */
  void sendCommand(String command) {
    _logger.fine('> $command');
    _connection.write('$command\r\n');
  }

  /**
   * Closes the connection.
   */
  void _close() {
    _connection.close();
  }

  /**
   * This [onData] handler reads the message that the server sent us.
   */
  void _onData(List<int> chunk) {
    if (_ignoreData || chunk == null || chunk.length == 0) return;

    _remainder.addAll(chunk);

    // If the message comes in pieces, it does not end with \n.
    if (_remainder.last != 0x0A) return;

    var message = new String.fromCharCodes(_remainder);

    // A multi line reply, wait until ending.
    if (new RegExp('(?:^|\n)\d{3}-.+\$').hasMatch(message)) return;

    _remainder.clear();

    _logger.fine(message);

    assert(_currentAction is Function);

    _currentAction(message);
  }

  /**
   * Upgrades the connection to use TLS.
   */
  void _upgradeConnection(callback) {
    _ignoreData = true;

    _close();

    _connect(secured: true).then((_) {
      _ignoreData = false;
      callback();
    });
  }

  void _actionGreeting(String message) {
    if (message.startsWith('220') == false) {
      _logger.severe('Invalid greeting from server: $message');
      return;
    }

    _currentAction = _actionEHLO;
    sendCommand('EHLO ${options.name}');
  }

  void _actionEHLO(String message) {
    // EHLO wasn't cool? Let's go with HELO.
    if (message.startsWith('2') == false) {
      _currentAction = _actionHELO;
      sendCommand('HELO ${options.name}');
      return;
    }

    // The server supports TLS and we haven't switched to it yet, so let's do it.
    if (_connection is! SecureSocket && new RegExp('[ \\-]STARTTLS\\r?\$', caseSensitive: false, multiLine: true).hasMatch(message)) {
      sendCommand('STARTTLS');
      _currentAction = _actionStartTLS;
      return;
    }

    if (new RegExp('AUTH(?:\\s+[^\\n]*\\s+|\\s+)PLAIN', caseSensitive: false).hasMatch(message)) supportedAuthentications.add('PLAIN');
    if (new RegExp('AUTH(?:\\s+[^\\n]*\\s+|\\s+)LOGIN', caseSensitive: false).hasMatch(message)) supportedAuthentications.add('LOGIN');
    if (new RegExp('AUTH(?:\\s+[^\\n]*\\s+|\\s+)CRAM-MD5', caseSensitive: false).hasMatch(message)) supportedAuthentications.add('CRAM-MD5');
    if (new RegExp('AUTH(?:\\s+[^\\n]*\\s+|\\s+)XOAUTH', caseSensitive: false).hasMatch(message)) supportedAuthentications.add('XOAUTH');
    if (new RegExp('AUTH(?:\\s+[^\\n]*\\s+|\\s+)XOAUTH2', caseSensitive: false).hasMatch(message)) supportedAuthentications.add('XOAUTH2');

    _authenticateUser();
  }

  void _actionHELO(String message) {
    if (message.startsWith('2') == false) {
      _logger.severe('Invalid response for EHLO/HELO: $message');
      return;
    }

    _authenticateUser();
  }

  void _actionStartTLS(String message) {
    if (message.startsWith('2') == false) {
      _currentAction = _actionHELO;
      sendCommand('HELO ${options.name}');
      return;
    }

    _upgradeConnection(() {
      _currentAction = _actionEHLO;
      sendCommand('EHLO ${options.name}');
    });
  }

  void _authenticateUser() {
    if (options.username == null) {
      _currentAction = _actionIdle;
      _onIdleController.add(true);
      return;
    }

    // TODO: Support other auth methods.

    _currentAction = _actionAuthenticateLoginUser;
    sendCommand('AUTH LOGIN');
  }

  void _actionAuthenticateLoginUser(String message) {
    if (message.startsWith('334 VXNlcm5hbWU6') == false) {
      throw 'Invalid logic sequence while waiting for "334 VXNlcm5hbWU6": $message';
    }

    _currentAction = _actionAuthenticateLoginPassword;
    sendCommand(CryptoUtils.bytesToBase64(options.username.codeUnits));
  }

  void _actionAuthenticateLoginPassword(String message) {
    if (message.startsWith('334 UGFzc3dvcmQ6') == false) {
      throw 'Invalid logic sequence while waiting for "334 UGFzc3dvcmQ6": $message';
    }

    _currentAction = _actionAuthenticateComplete;
    sendCommand(CryptoUtils.bytesToBase64(options.password.codeUnits));
  }

  void _actionAuthenticateComplete(String message) {
    if (message.startsWith('2') == false) {
      throw 'Invalid login: $message';
    }

    _currentAction = _actionIdle;
    _onIdleController.add(true);
  }

  var _recipientIndex = 0;

  void _actionMail(String message) {
    if (message.startsWith('2') == false) {
      throw 'Mail from command failed: $message';
    }

    var recipient;

    // We are processing the last recipient.
    if (_recipientIndex == _envelope.recipients.length - 1) {
      _recipientIndex = 0;

      _currentAction = _actionRecipient;
      recipient = _envelope.recipients[_recipientIndex];
    }

    // There are more recipients to process. We need to send RCPT TO multiple times.
    else {
      _currentAction = _actionMail;
      recipient = _envelope.recipients[++_recipientIndex];
    }

    sendCommand('RCPT TO:<${_sanitizeEmail(recipient)}>');
  }

  void _actionRecipient(String message) {
    if (message.startsWith('2') == false) {
      _logger.severe('Recipient failure: $message');
      return;
    }

    _currentAction = _actionData;
    sendCommand('DATA');
  }

  void _actionData(String message) {
    // The response should be either 354 or 250.
    if (message.startsWith('2') == false && message.startsWith('3') == false) {
      throw 'Data command failed: $message';
    }

    _currentAction = _actionFinishEnvelope;
    _envelope.getContents().then(sendCommand);
  }

  _actionFinishEnvelope(String message) {
    if (message.startsWith('2') == false) {
      throw 'Could not send email: $message';
    }

    _currentAction = _actionIdle;
    _onSendController.add(_envelope);
    _envelope = null;
  }

  void _actionIdle(String message) {
    if (int.parse(message.substring(0, 1)) > 3) {
      throw 'Error: $message';
    }

    throw 'We should never get here -- bug? Message: $message';
  }
}