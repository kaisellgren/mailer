import '../smtp_server.dart';

SmtpServer gmail(String username, String password) =>
    SmtpServer('smtp.gmail.com',
        port: 465, username: username, password: password);
