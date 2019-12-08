import '../smtp_server.dart';

SmtpServer gmail(String username, String password) =>
    SmtpServer('smtp.gmail.com', username: username, password: password);

SmtpServer gmailXoauth2(String token) =>
    SmtpServer('smtp.gmail.com', xoauth2Token: token);
