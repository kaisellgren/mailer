import '../smtp_server.dart';

SmtpServer yahoo(String username, String password) =>
    SmtpServer('smtp.mail.yahoo.com',
        port: 465, username: username, password: password, ssl: true);
