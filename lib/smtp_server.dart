export 'smtp_server/gmail.dart';
export 'smtp_server/hotmail.dart';
export 'smtp_server/mailgun.dart';
export 'smtp_server/qq.dart';
export 'smtp_server/yahoo.dart';
export 'smtp_server/yandex.dart';
export 'smtp_server/zoho.dart';

class SmtpServer {
  final String host;
  final int port;
  final bool ignoreBadCertificate;
  final bool ssl;
  final bool allowInsecure;
  final String? username;
  final String? password;
  final String? xoauth2Token;

  SmtpServer(this.host,
      {this.port = 587,
      String? name,
      this.ignoreBadCertificate = false,
      this.ssl = false,
      this.allowInsecure = false,
      this.username,
      this.password,
      this.xoauth2Token});
}
