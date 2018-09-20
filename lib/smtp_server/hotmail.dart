import '../smtp_server.dart';

SmtpServer yahoo(String username, String password) =>
    new SmtpServer('smtp.live.com', username: username, password: password);
