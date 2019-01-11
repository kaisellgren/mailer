import 'message.dart';
import 'problem.dart';

class SendReport {
  final Message mail;
  final bool sent;
  final List<Problem> validationProblems;

  SendReport(this.mail, this.sent, {this.validationProblems});
}
