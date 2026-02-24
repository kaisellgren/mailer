import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:test/test.dart';

import 'mock_smtp_server.dart';

void main() {
  group('RFC 3030 Support', () {
    late MockSmtpServer mockServer;

    setUp(() async {
      mockServer = MockSmtpServer();
      await mockServer.start();
    });

    tearDown(() async {
      await mockServer.stop();
    });

    test('Uses BDAT when CHUNKING is supported', () async {
      final smtpServer = SmtpServer('localhost', port: mockServer.port, allowInsecure: true);
      final message = Message()
        ..from = 'sender@example.com'
        ..recipients.add('recipient@example.com')
        ..subject = 'Test BDAT'
        ..text = 'This is a test message for BDAT support.';

      await send(message, smtpServer);

      // Verify log contains BDAT commands.
      expect(mockServer.serverLog.any((l) => l.startsWith('BDAT')), isTrue);
      // Depending on implementation, it might send 'LAST' or not in the same line or separate BDATs.
      // mailer implementation sends "BDAT <size> LAST"
      expect(mockServer.serverLog.any((l) => l.startsWith('BDAT') && l.contains('LAST')), isTrue);
    });

    test('Does NOT use DATA when CHUNKING available (preferred)', () async {
      // Ideally we prefer BDAT if available.
      final smtpServer = SmtpServer('localhost', port: mockServer.port, allowInsecure: true);
      final message = Message()
        ..from = 'sender@example.com'
        ..recipients.add('recipient@example.com')
        ..subject = 'Test BDAT Preference'
        ..text = 'Prefer BDAT';

      await send(message, smtpServer);

      expect(mockServer.serverLog, isNot(contains('DATA')));
    });
  });
}
