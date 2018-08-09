class ServerResponse {
  final String responseCode;

  /// Every line received from the server is one entry in the message list.
  final List<String> responseLines;

  ServerResponse(this.responseCode, this.responseLines);
}

