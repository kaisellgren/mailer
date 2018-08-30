import '../smtp_server.dart';

SmtpServer gmail(String username, String password) =>
    SmtpServer('smtp.gmail.com', username: username, password: password);
