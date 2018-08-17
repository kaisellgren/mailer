part of mailer;

/*!
 * This file contains pre-defined helper options.
 *
 * This means the user has to only fill in the username/password.
 */

class GmailSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.gmail.com';
  final int port = 465;
  final bool secured = true;
}

class YahooSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mail.yahoo.com';
  final int port = 465;
  final bool secured = true;
}

class HotmailSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.live.com';
  final int port = 587;
  final bool secured = true;
}

class HotEeSmtpOptions extends SmtpOptions {
  final String hostName = 'mail.hot.ee'; // TODO: insecure?
}

class MailEeSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mail.ee'; // TODO: insecure?
}

class AmazonSESSmtpOptions extends SmtpOptions {
  final String hostName = 'email-smtp.us-east-1.amazonaws.com';
  final int port = 465;
  final bool secured = true;
}

class ZohoSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.zoho.com';
  final int port = 465;
  final bool secured = true;
  // TODO: Authentication method = LOGIN?
}

class ICloudSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mail.me.com';
  final int port = 587;
  final bool secured = true;
}

class SendGridSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.sendgrid.net'; // TODO: insecure?
  final int port = 587;
}

class MailgunSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mailgun.org'; // TODO: insecure?
  final int port = 587;
}

class PostmarkSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.postmarkapp.com'; // TODO: insecure?
  final int port = 25;
}

class YandexSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.yandex.com';
  final int port = 465;
  final bool secured = true;
}

class MailRuSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.mail.ru';
  final int port = 465;
  final bool secured = true;
}

class DynectEmailSmtpOptions extends SmtpOptions {
  // TODO: insecure?
  final String hostName = 'smtp.dynect.net';
  final int port = 25;
}

class MandrillSmtpOptions extends SmtpOptions {
  // TODO: insecure?
  final String hostName = 'smtp.mandrillapp.com';
  final int port = 587;
}

class MailjetSmtpOptions extends SmtpOptions {
  // TODO: insecure?
  final String hostName = 'in.mailjet.com';
  final int port = 587;
}

class OpenMailBoxSmtpOptions extends SmtpOptions {
  final String hostName = 'smtp.openmailbox.org';
  final int port = 465;
  final bool secured = true;
}
