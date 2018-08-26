import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';

import '../capabilities.dart';
import '../../entities/address.dart';
import '../../entities/attachment.dart';
import '../../entities/message.dart';

part 'adapter.dart';
part 'ir_content.dart';
part 'ir_header.dart';
part 'ir_message.dart';

const String _eol = '\r\n';

List<int> _to8(String s) => utf8.encode(s);
final List<int> _eol8 = _to8(_eol);

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

abstract class _IROutput {
  Stream<List<int>> out(_IRMetaInformation irMetaInformation);
}
