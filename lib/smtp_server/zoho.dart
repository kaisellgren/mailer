import '../smtp_server.dart';

SmtpServer zoho(String username, String password) => SmtpServer('smtp.zoho.com',
    port: 465, ssl: true, username: username, password: password);
