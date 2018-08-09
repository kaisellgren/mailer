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

/// This exception is thrown when no secure connection can be established
/// and [SmtpOptions.securedOnly] is true.
class SmtpUnsecureException extends SmtpClientException {
  SmtpUnsecureException(String message) : super(message);
}
