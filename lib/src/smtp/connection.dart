import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:logging/logging.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mailer/src/smtp/exceptions.dart';

import 'capabilities.dart';

/// This class contains all relevant data for one smtp connection/session.
///
/// This includes the socket, smtp-options, but also other objects, relevant
/// for an smtp session, like an input queue.

final _logger = Logger('Connection');

class ServerResponse {
  final String responseCode;

  /// Every line received from the server is one entry in the message list.
  final List<String> responseLines;

  ServerResponse(this.responseCode, this.responseLines);
}

class Connection {
  final SmtpServer server;
  final Duration timeout;
  DateTime? _connectionOpenStart;

  DateTime? get connectionOpenStart => _connectionOpenStart;

  late Capabilities capabilities;

  // Done with close function.
  // ignore: close_sinks
  Socket? _socket;
  StreamQueue<String>? _socketIn;

  Connection(this.server, {Duration? timeout})
      // ignore: unnecessary_this
      : this.timeout = timeout ?? const Duration(seconds: 60);

  bool get isSecure => _socket != null && _socket is SecureSocket;

  Future sendStream(Stream<List<int>> s) => _socket!.addStream(s);

  /// Returns the next message from server.  An exception is thrown if
  /// [acceptedRespCodes] is not empty and the response code from the server
  /// does not start with any of the strings in [acceptedRespCodes];
  Future<ServerResponse?> send(String command,
      {List<String>? acceptedRespCodes = const ['2'],
      String? expect,
      bool waitForResponse = true}) async {
    // Send the new command.
    _logger.fine('> $command');
    if (command.isNotEmpty) {
      _socket!.write('$command\r\n');
    }

    if (!waitForResponse) {
      // Even though we don't wait for a response, we still wait until the
      // command has been sent.
      await _socket!.flush().timeout(timeout);
      return null;
    }

    final messages = <String>[];
    String responseCode;

    String? currentLine;

    // A response from the server always has a space as the 4th character
    // for the _last_ line of a response.
    // Multi-line responses have '-' as 4th character except for the last
    // line.
    while (currentLine == null ||
        (currentLine.length > 3 && currentLine[3] != ' ')) {
      var hasNext = await _socketIn!.hasNext.timeout(timeout);
      if (!hasNext) {
        throw SmtpClientCommunicationException(
            'Socket was closed even though a response was expected.');
      }

      // Let's timeout if we don't receive anything from the other side.
      // This is possible if we for instance connect to an SSL port where the
      // socket connection succeeds, but we never receive anything because we
      // are stuck in the SSL negotiation process.
      currentLine = await _socketIn!.next.timeout(timeout);

      messages.add(currentLine.substring(4));
    }

    responseCode = currentLine.substring(0, 3);

    var mString = messages.map((m) => '< $responseCode $m').join('\n');
    _logger.fine(mString);

    if (acceptedRespCodes != null &&
        acceptedRespCodes.isNotEmpty &&
        !acceptedRespCodes.any((start) => responseCode.startsWith(start))) {
      var msg =
          'After sending $command, response did not start with any of: $acceptedRespCodes.';
      msg += '\nResponse from server: $mString';
      _logger.warning(msg);
      throw SmtpClientCommunicationException(msg);
    }

    return ServerResponse(responseCode, messages);
  }

  /// Upgrades the connection to use TLS.
  Future<void> upgradeConnection() async {
    // SecureSocket.secure suggests to call socketSubscription.pause().
    // A StreamQueue always pauses unless we explicitly call next().
    // So we don't need to call pause() ourselves.
    _socket = await SecureSocket.secure(_socket!,
        onBadCertificate: (_) => server.ignoreBadCertificate);
    _setSocketIn();
  }

  /// Initializes a connection to the given server.
  Future<void> connect() async {
    _connectionOpenStart = DateTime.now();
    _logger.finer('Connecting to ${server.host} at port ${server.port}.');

    // Secured connection was demanded by the user.
    if (server.ssl) {
      _socket = await SecureSocket.connect(server.host, server.port,
          onBadCertificate: (_) => server.ignoreBadCertificate,
          timeout: timeout);
    } else {
      _socket =
          await Socket.connect(server.host, server.port, timeout: timeout);
    }
    _socket!.timeout(timeout);

    _setSocketIn();
  }

  Future<void> close() async {
    if (_socket != null) await _socket!.close();
    if (_socketIn != null) await _socketIn!.cancel(immediate: true);
  }

  void _setSocketIn() {
    if (_socketIn != null) {
      _socketIn!.cancel();
    }
    _socketIn = StreamQueue<String>(
        utf8.decoder.bind(_socket!).transform(const LineSplitter()));
  }

  void verifySecuredConnection() {
    if (!server.allowInsecure && !isSecure) {
      _socket!.close();
      throw SmtpUnsecureException('Aborting because connection is not secure');
    }
  }
}
