import '../smtp_server.dart';

SmtpServer mailgun(String username, String password) =>
    SmtpServer('smtp.mailgun.org', username: username, password: password);
