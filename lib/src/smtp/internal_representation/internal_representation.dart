import 'dart:async';
import 'dart:convert' as convert;

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:mailer/src/utils.dart';

import '../../entities/address.dart';
import '../../entities/attachment.dart';
import '../../entities/message.dart';
import '../capabilities.dart';
import 'conversion.dart';

part 'ir_content.dart';
part 'ir_header.dart';
part 'ir_message.dart';

// "An 'encoded-word' may not be more than 75 characters long, including
// 'charset', 'encoding', 'encoded-text', and delimiters."
const maxEncodedLength = 75; // as per RFC2047
const maxLineLength = 800;
const maxBase64LineLength = 76; // as per RFC2045
// «The encoded output stream must be represented in lines of no more
// than 76 characters each.»

// From https://docs.flutter.io/flutter/foundation/describeEnum.html
String _describeEnum(Object enumEntry) {
  final description = enumEntry.toString();
  final indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}

class _IRMetaInformation {
  final Capabilities capabilities;

  _IRMetaInformation(this.capabilities);
}

abstract class _IROutput {
  Stream<List<int>> out(_IRMetaInformation irMetaInformation);
}
