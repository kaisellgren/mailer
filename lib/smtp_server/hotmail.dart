import '../smtp_server.dart';

SmtpServer yahoo(String username, String password) =>
    SmtpServer('smtp.live.com', username: username, password: password);
