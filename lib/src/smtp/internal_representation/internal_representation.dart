import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart' as collection;
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


class _IRMetaInformation {
  final Capabilities capabilities;

  _IRMetaInformation(this.capabilities);
}

abstract class _IROutput {
  Stream<List<int>> _fromString(String s) =>
      Stream.fromIterable([utf8.encode(s)]);

  Stream<List<int>> out(_IRMetaInformation irMetaInformation);
}
