import 'message.dart';

class SendReport {
  final Message mail;
  final DateTime connectionOpened;
  final DateTime messageSendingStart;
  final DateTime messageSendingEnd;

  SendReport(this.mail, this.connectionOpened, this.messageSendingStart,
      this.messageSendingEnd);

  @override
  String toString() {
    return 'Message successfully sent.\n'
        'Connection was opened at: $connectionOpened.\n'
        'Sending the message started at: $messageSendingStart and finished at: $messageSendingEnd.';
  }
}
