import '../smtp_server.dart';

SmtpServer gmail(String username, String password) =>
    new SmtpServer('smtp.mailgun.org', username: username, password: password);
