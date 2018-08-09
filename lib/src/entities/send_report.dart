import 'mail.dart';
import 'problem.dart';

class SendReport {
  final Mail mail;
  final bool sent;
  final List<Problem> validationProblems;

  SendReport(this.mail, this.sent, {this.validationProblems});
}
