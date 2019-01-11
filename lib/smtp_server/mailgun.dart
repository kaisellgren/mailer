import '../smtp_server.dart';

SmtpServer mailgun(String username, String password) =>
    new SmtpServer('smtp.mailgun.org', username: username, password: password);
