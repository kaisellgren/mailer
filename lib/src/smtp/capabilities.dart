import 'package:meta/meta.dart';

@visibleForTesting
Capabilities capabilitiesForTesting(
    {bool startTls = false,
    bool smtpUtf8 = false,
    bool authPlain = true,
    bool authLogin = false,
    bool authXoauth2 = false,
    List<String> all = const <String>[]}) {
  return Capabilities._values(
      startTls, smtpUtf8, authPlain, authLogin, authXoauth2, all);
}

class Capabilities {
  final bool startTls;
  final bool smtpUtf8;
  final bool authPlain;
  final bool authLogin;
  final bool authXoauth2;
  final List<String> all;

  const Capabilities()
      : startTls = false,
        smtpUtf8 = false,
        authPlain = true,
        authLogin = false,
        authXoauth2 = false,
        all = const <String>[];

  const Capabilities._values(this.startTls, this.smtpUtf8, this.authPlain,
      this.authLogin, this.authXoauth2, this.all);

  factory Capabilities.fromResponse(Iterable<String> ehloMessage) {
    final capabilities =
        List<String>.unmodifiable(ehloMessage.map((m) => m.toUpperCase()));

    var startTls = false;
    var smtpUtf8 = false;
    var plain = false;
    var login = false;
    var xoauth2 = false;

    for (var cap in capabilities) {
      if (cap.contains('STARTTLS')) {
        startTls = true;
      } else if (cap.contains('SMTPUTF8')) {
        smtpUtf8 = true;
      } else if (cap.startsWith('AUTH ')) {
        var authMethods = cap.split(' ').skip(1); // First is 'AUTH'
        plain = authMethods.contains('PLAIN');
        login = authMethods.contains('LOGIN');
        xoauth2 = authMethods.contains('XOAUTH2');
      }
    }

    return Capabilities._values(
        startTls, smtpUtf8, plain, login, xoauth2, capabilities);
  }
}
