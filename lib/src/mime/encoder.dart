import 'dart:async';
import 'dart:convert' as convert;
import 'mime.dart';
import 'stream_splitter.dart';

abstract class ContentEncoder {
  String get transferEncoding;
  Stream<List<int>> encode(Stream<List<int>> input);
}

class Base64ContentEncoder extends ContentEncoder {
  @override
  String get transferEncoding => 'base64';

  @override
  Stream<List<int>> encode(Stream<List<int>> input) {
    return input
        .transform(convert.base64.encoder)
        .transform(convert.ascii.encoder)
        .transform(StreamSplitter(maxBase64LineLength));
  }
}

class BinaryContentEncoder extends ContentEncoder {
  @override
  String get transferEncoding => 'binary';

  @override
  Stream<List<int>> encode(Stream<List<int>> input) => input;
}
