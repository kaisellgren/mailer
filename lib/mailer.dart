library mailer;

import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:logging/logging.dart';
import 'package:charcode/ascii.dart';

import 'src/util.dart';

part 'src/address.dart';
part 'src/envelope.dart';
part 'src/transport.dart';
part 'src/attachment.dart';
part 'src/sendmail_transport.dart';
part 'src/smtp/helper_options.dart';
part 'src/smtp/smtp_client.dart';
part 'src/smtp/smtp_options.dart';
part 'src/smtp/smtp_transport.dart';

var _logger = new Logger('mailer');

printDebugInformation() {
  _logger.onRecord.listen(print);
}
