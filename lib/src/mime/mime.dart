import 'dart:async';
import 'dart:convert' as convert;

import 'package:intl/intl.dart';

import '../core/address.dart';
import '../core/attachment.dart';
import '../core/message.dart';
import '../smtp/capabilities.dart';
import '../utils.dart';
import 'encoder.dart';
import 'stream_splitter.dart';

part 'mime_header.dart';
part 'mime_message.dart';
part 'mime_part.dart';

// "An 'encoded-word' may not be more than 75 characters long, including
// 'charset', 'encoding', 'encoded-text', and delimiters."
const maxEncodedLength = 75; // as per RFC2047
const maxLineLength = 800;
const maxBase64LineLength = 76; // as per RFC2045
// «The encoded output stream must be represented in lines of no more
// than 76 characters each.»

class RenderContext {
  final Capabilities capabilities;

  RenderContext(this.capabilities);
}

abstract class _MimeOutput {
  // The output of the mime message is a stream of objects, which can be either
  // String or List<int>.
  Stream<Object> out(RenderContext renderContext);
}
