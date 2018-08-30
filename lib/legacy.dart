import 'dart:async';
import 'dart:io';

import 'package:mailer/smtp_server.dart';
import 'package:mailer/src/smtp/smtp_client.dart';

import 'mailer.dart';

@deprecated
class Envelope extends Message {}

@deprecated
class SmtpTransport {
  SmtpOptions smtpOptions;
  SmtpTransport(this.smtpOptions);

  Future send(Envelope message) async {
    final SmtpServer smtpServer = new SmtpServer(smtpOptions.hostName,
        port: smtpOptions.port,
        allowInsecure: true,
        username: smtpOptions.username,
        password: smtpOptions.password,
        ignoreBadCertificate: smtpOptions.ignoreBadCertificate,
        ssl: smtpOptions.secured);
    SmtpClient client = new SmtpClient(smtpServer);

    return client.send(message);
  }

  Future sendAll(List<Envelope> envelopes) => Future.wait(envelopes.map(send));
}

@deprecated
class SmtpOptions {
  String name = Platform.localHostname;
  String hostName;
  int port = 465;
  bool requiresAuthentication = false;
  bool ignoreBadCertificate = true;
  bool secured = false;
  String username;
  String password;
}

@deprecated
// Use
// ```
// import 'package:mailer/smtp_server/gmail.dart';
// gmail(username, password);
// ```
class GmailSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.gmail.com';
  final int port = 465;
  final bool secured = true;
}

@deprecated
// Use
// ```
// import 'package:mailer/smtp_server/yahoo.dart';
// yahoo(username, password);
// ```
class YahooSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mail.yahoo.com';
  final int port = 465;
  final bool secured = true;
}

@deprecated
// Use
// ```
// import 'package:mailer/smtp_server/hotmail.dart';
// hotmail(username, password);
// ```
class HotmailSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.live.com';
  final int port = 587;
  final bool secured = true;
}

@deprecated
// Create an SmtpServer instance:
// ```
// import 'package:mailer/smtp_server.dart';
// final s = SmtpServer(...);
// ```
class HotEeSmtpOptions extends SmtpOptions {
  final String hostName = 'mail.hot.ee'; // TODO: insecure?
}

@deprecated
class MailEeSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mail.ee'; // TODO: insecure?
}

@deprecated
class AmazonSESSmtpOptions extends SmtpOptions {
  final String hostName = 'email-smtp.us-east-1.amazonaws.com';
  final int port = 465;
  final bool secured = true;
}

@deprecated
class ZohoSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.zoho.com';
  final int port = 465;
  final bool secured = true;
// TODO: Authentication method = LOGIN?
}

@deprecated
class ICloudSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mail.me.com';
  final int port = 587;
  final bool secured = true;
}

@deprecated
class SendGridSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.sendgrid.net'; // TODO: insecure?
  final int port = 587;
}

@deprecated
class MailgunSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mailgun.org'; // TODO: insecure?
  final int port = 587;
}

@deprecated
class PostmarkSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.postmarkapp.com'; // TODO: insecure?
  final int port = 25;
}

@deprecated
class YandexSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.yandex.com';
  final int port = 465;
  final bool secured = true;
}

@deprecated
class MailRuSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mail.ru';
  final int port = 465;
  final bool secured = true;
}

@deprecated
class DynectEmailSmtpOptions extends SmtpOptions {
  // TODO: insecure?
  final String hostName = 'smtp.dynect.net';
  final int port = 25;
}

@deprecated
class MandrillSmtpOptions extends SmtpOptions {
  // TODO: insecure?
  final String hostName = 'smtp.mandrillapp.com';
  final int port = 587;
}

@deprecated
class MailjetSmtpOptions extends SmtpOptions {
  // TODO: insecure?
  final String hostName = 'in.mailjet.com';
  final int port = 587;
}

@deprecated
class OpenMailBoxSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.openmailbox.org';
  final int port = 465;
  final bool secured = true;
}
