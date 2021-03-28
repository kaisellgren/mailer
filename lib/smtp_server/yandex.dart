import '../smtp_server.dart';

SmtpServer yandex(String username, String password) =>
    SmtpServer('smtp.yandex.com',
        port: 465, ssl: true, username: username, password: password);
