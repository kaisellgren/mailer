import '../smtp_server.dart';

SmtpServer hotmail(String username, String password) =>
    SmtpServer('smtp.live.com', username: username, password: password);
