import 'dart:io';

class SmtpOptions {
  final String name;
  final String host;
  final int port;
  final bool ignoreBadCertificate;
  final bool ssl;
  final bool securedOnly;
  final String username;
  final String password;

  SmtpOptions(this.host,
      {int port,
      String name,
      bool ignoreBadCertificate,
      bool ssl,
      bool securedOnly,
      this.username,
      this.password})
      : this.port = port ?? 587,
        this.name = name ?? Platform.localHostname,
        this.ignoreBadCertificate = ignoreBadCertificate ?? false,
        this.ssl = ssl ?? false,
        this.securedOnly = securedOnly ?? true;
}
