import 'dart:async';

import 'package:dart2_constant/convert.dart' as convert;
import 'package:intl/intl.dart';

import 'conversion.dart';
import '../capabilities.dart';
import '../../entities/address.dart';
import '../../entities/attachment.dart';
import '../../entities/message.dart';
import '../../entities/problem.dart';

part 'ir_content.dart';
part 'ir_header.dart';
part 'ir_message.dart';

// "An 'encoded-word' may not be more than 75 characters long, including
// 'charset', 'encoding', 'encoded-text', and delimiters."
const maxEncodedLength = 75; // as per RFC2047
const splitOverLength = 80;
const maxLineLength = 800;

// From https://docs.flutter.io/flutter/foundation/describeEnum.html
String _describeEnum(Object enumEntry) {
  final String description = enumEntry.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}

class _IRMetaInformation {
  final Capabilities capabilities;

  _IRMetaInformation(this.capabilities);
}

class IRProblemException implements Exception {
  final Problem problem;

  IRProblemException(this.problem);
}

abstract class _IROutput {
  Stream<List<int>> out(_IRMetaInformation irMetaInformation);
}
