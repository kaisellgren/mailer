import 'dart:io';

class SmtpServer {
  final String name;
  final String host;
  final int port;
  final bool ignoreBadCertificate;
  final bool ssl;
  final bool allowInsecure;
  final String username;
  final String password;

  SmtpServer(this.host,
      {int port,
      String name,
      bool ignoreBadCertificate,
      bool ssl,
      bool allowInsecure,
      this.username,
      this.password})
      : this.port = port ?? 587,
        this.name = name ?? Platform.localHostname,
        this.ignoreBadCertificate = ignoreBadCertificate ?? false,
        this.ssl = ssl ?? false,
        this.allowInsecure = allowInsecure ?? false;
}
