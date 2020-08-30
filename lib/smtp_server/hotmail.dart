import '../smtp_server.dart';

SmtpServer hotmail(String username, String password) =>
    SmtpServer('smtp-mail.outlook.com', username: username, password: password);
