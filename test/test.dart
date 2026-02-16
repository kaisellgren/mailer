import 'address_test.dart' as address_test;
import 'binarymime_test.dart' as binarymime_test;
import 'idna_test.dart' as idna_test;
import 'message_out_test.dart' as message_out_test;
import 'punycode_test.dart' as punycode_test;
import 'rfc3030_test.dart' as rfc3030_test;
import 'smtp_client_test.dart' as client_test;
import 'split_test.dart' as split_test;
import 'stream_splitter_test.dart' as stream_splitter_test;
import 'validator_test.dart' as validator_test;

import 'package:test/test.dart';

void main() {
  group('address_test', address_test.main);
  group('binarymime_test', binarymime_test.main);
  group('idna_test', idna_test.main);
  group('message_out_test', message_out_test.main);
  group('punycode_test', punycode_test.main);
  group('rfc3030_test', rfc3030_test.main);
  group('client_test', client_test.main);
  group('split_test', split_test.main);
  group('stream_splitter_test', stream_splitter_test.main);
  group('validator_test', validator_test.main);
}
