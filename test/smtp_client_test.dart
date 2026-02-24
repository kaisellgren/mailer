import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:test/test.dart';

SmtpServer incorrectCredentials = gmail('mister@gmail.com', 'wrongpass');

void main() {
  test('SmtpClient.checkCredentials() throws SmtpClientAuthenticationException', () async {
    expect(checkCredentials(incorrectCredentials, timeout: const Duration(seconds: 5)),
        throwsA(TypeMatcher<SmtpClientAuthenticationException>()));
  }); // Removed skip: false as it's default
}
