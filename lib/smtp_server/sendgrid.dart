import '../smtp_server.dart';

SmtpServer sendgrid(String username, String password) =>
    SmtpServer('smtp.sendgrid.net',
        username: username, password: password);
