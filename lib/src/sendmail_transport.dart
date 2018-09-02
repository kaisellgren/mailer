part of mailer;

abstract class SendmailTransport extends Transport {
  /**
   * Specifies the path to sendmail program.
   *
   * You can change this value if it's wrong.
   */
  String sendmailPath = '/usr/sbin/sendmail';
}