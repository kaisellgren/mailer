import '../core/problem.dart';

abstract class MailerException implements Exception {
  /// A short description of the problem.
  final String message;
  final List<Problem> problems;

  MailerException(this.message, {this.problems = const []});

  @override
  String toString() => message;
}

/// This exception is thrown when the server either doesn't accept
/// the authentication type or the username password is incorrect.
class SmtpClientAuthenticationException extends MailerException {
  SmtpClientAuthenticationException(super.message);
}

/// This exception is thrown when the server unexpectedly returns a response
/// code which differs to our accepted response codes (usually 2xx).
class SmtpClientCommunicationException extends MailerException {
  SmtpClientCommunicationException(super.message);
}

/// This exception is thrown when no secure connection can be established
/// and [SmtpServer.allowInsecure] is false.
class SmtpUnsecureException extends MailerException {
  SmtpUnsecureException(super.message);
}

class SmtpMessageValidationException extends MailerException {
  SmtpMessageValidationException(super.message, List<Problem> problems) : super(problems: problems);
}

class SmtpNoGreetingException extends MailerException {
  SmtpNoGreetingException(super.message);
}
