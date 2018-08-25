import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:mailer/smtp_server.dart';
import 'exceptions.dart';
import 'server_response.dart';

/**
 * This class contains all relevant data for one smtp connection/session.
 *
 * This includes the socket, smtp-options, but also other objects, relevant
 * for an smtp session, like an input queue.
 *
 * By passing this object around, we will be thread safe.
 * As sending mail is a Future, it is conceivable to send a lot of mails in
 * parallel using the same client, and then Future.wait for all mails to finish.
 *
 * This wouldn't work if we stored connection information in the client itself.
 **/

final _logger = new Logger('Connection');

class Connection {
  final SmtpServer _server;
  Socket _socket;
  StreamQueue<String> _socketIn;

  Connection(this._server);

  bool get isSecure => _socket != null && _socket is SecureSocket;

  Future<void> sendStream(Stream<List<int>> s) => _socket.addStream(s);

  /// Returns the next message from server.  An exception is thrown if
  /// [acceptedRespCodes] is not empty and the response code form the server
  /// does not start with any of the strings in [acceptedRespCodes];
  Future<ServerResponse> send(String command,
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

    return new ServerResponse(responseCode, messages);
  }

  /// Upgrades the connection to use TLS.
  Future<void> upgradeConnection() async {
    // SecureSocket.secure suggests to call socketSubscription.pause().
    // A StreamQueue always pauses unless we explicitly call next().
    // So we don't need to call pause() ourselves.
    _socket = await SecureSocket.secure(_socket,
        onBadCertificate: (_) => _server.ignoreBadCertificate);
    _setSocketIn();
  }

  /// Initializes a connection to the given server.
  Future<void> connect() async {
    _logger.finer("Connecting to ${_server.host} at port ${_server.port}.");

    // Secured connection was demanded by the user.
    if (_server.ssl) {
      _socket = await SecureSocket.connect(_server.host, _server.port,
          onBadCertificate: (_) => _server.ignoreBadCertificate);
    } else {
      _socket = await Socket.connect(_server.host, _server.port);
    }
    _socket.timeout(const Duration(seconds: 60));

    _setSocketIn();
  }

  Future<void> close() => _socket.close();

  void _setSocketIn() {
    if (_socketIn != null) {
      _socketIn.cancel();
    }
    _socketIn = new StreamQueue<String>(
        _socket.transform(utf8.decoder).transform(const LineSplitter()));
  }

  void verifySecuredConnection() {
    if (!_server.allowInsecure && !isSecure) {
      throw new SmtpUnsecureException(
          "Aborting because connection is not secure");
    }
  }
}
