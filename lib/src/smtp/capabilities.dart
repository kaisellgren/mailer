class Capabilities {
  final bool startTls;
  final bool smtpUtf8;
  final bool authPlain;
  final bool authLogin;
  final List<String> all;

  const Capabilities()
      : startTls = false,
        smtpUtf8 = false,
        authPlain = true,
        authLogin = false,
        all = const <String>[];

  const Capabilities._values(
      this.startTls, this.smtpUtf8, this.authPlain, this.authLogin, this.all);

  factory Capabilities.fromResponse(Iterable<String> ehloMessage) {
    final List<String> capabilities =
        new List.unmodifiable(ehloMessage.map((m) => m.toUpperCase()));

    var startTls = false;
    var smtpUtf8 = false;
    var plain = false;
    var login = false;

    capabilities.forEach((cap) {
      if (cap.contains('STARTTLS')) {
        startTls = true;
      } else if (cap.contains('SMTPUTF8')) {
        smtpUtf8 = true;
      } else if (cap.startsWith('AUTH ')) {
        var authMethods = cap.split(' ').skip(1); // First is 'AUTH'
        plain = authMethods.contains('PLAIN');
        login = authMethods.contains('LOGIN');
      }
    });

    return new Capabilities._values(
        startTls, smtpUtf8, plain, login, capabilities);
  }
}
