import 'package:logging/logging.dart';

export 'package:mailer/entities.dart';
export 'src/smtp_client.dart';

var _logger = new Logger('mailer');

printDebugInformation() {
  _logger.onRecord.listen(print);
}
