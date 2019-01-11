import '../smtp_server.dart';

SmtpServer hotmail(String username, String password) =>
    new SmtpServer('smtp.live.com', username: username, password: password);
