import '../smtp_server.dart';

SmtpServer brevo(String username, String password) =>
    SmtpServer('smtp-relay.brevo.com', username: username, password: password);
