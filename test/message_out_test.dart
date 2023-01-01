library message_out_test;

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/src/smtp/capabilities.dart';
import 'package:mailer/src/smtp/internal_representation/internal_representation.dart';
import 'package:test/test.dart';

part 'messages/message_helpers.dart';

part 'messages/message_simple_utf8.dart';

part 'messages/message_utf8_from_header.dart';

part 'messages/message_utf8_long_subject_long_body.dart';

part 'messages/message_text_html_only.dart';

part 'messages/message_all.dart';

class MessageTest {
  final String name;
  final Message message;
  final String messageRegExpWithUtf8;
  final String messageRegExpWithoutUtf8;
  final Map<String, String> stringReplacements;

  MessageTest(this.name, this.message, this.messageRegExpWithUtf8,
      this.messageRegExpWithoutUtf8,
      {this.stringReplacements = const {}});
}

final testCases = [
  messageSimpleUtf8,
  messageUtf8FromHeader,
  messageUtf8LongSubjectLongBodyBelowLineLength,
  messageUtf8LongSubjectLongBodyAboveLineLength,
  messageHtmlOnly,
  messageTextOnly,
  messageAll
];

Future<bool> testMessage(Message message, String expectedRegExp,
    {bool smtpUtf8 = true,
    Map<String, String> stringReplacements = const {}}) async {
  var irContent = IRMessage(message);
  var capabilities = capabilitiesForTesting(smtpUtf8: smtpUtf8);
  var data = irContent.data(capabilities);
  var m = await data.fold<List<int>>(<int>[], (previous, element) {
    previous.addAll(element);
    return previous;
  });
  var mUtf8 = utf8.decoder.convert(m);
  stringReplacements.forEach((replaceThis, withThis) {
    mUtf8 = mUtf8.replaceAll(replaceThis, withThis);
  });
  //print('Testing: $mUtf8 against $expectedRegExp');
  return RegExp(expectedRegExp, multiLine: true).hasMatch(mUtf8);
}

void main() async {
  Logger.root.level = Level.ALL;
  // Logger.root.onRecord.listen((LogRecord rec) =>
  //     print('${rec.level.name}: ${rec.time}: ${rec.message}'));

  for (var testCase in testCases) {
    // If we have a StreamAttachment we can't send the same message twice.
    // In this case the testCase is a function which generates a `MessageTest`
    var tcUtf8 = (testCase is Function ? testCase() : testCase) as MessageTest;
    test(
      'message is correctly converted ${tcUtf8.name} (utf8)',
      () async => expect(
          testMessage(tcUtf8.message, tcUtf8.messageRegExpWithUtf8,
              smtpUtf8: true, stringReplacements: tcUtf8.stringReplacements),
          completion(equals(true)),
          reason: '${tcUtf8.name} (smtpUtf8)'),
    );

    // Recreate the testCase (for StreamAttachments)
    final tcWithoutUtf8 =
        (testCase is Function ? testCase() : testCase) as MessageTest;
    test(
        'message is correctly converted ${tcWithoutUtf8.name} (without utf8)',
        () async => expect(
            testMessage(
                tcWithoutUtf8.message, tcWithoutUtf8.messageRegExpWithoutUtf8,
                smtpUtf8: false, stringReplacements: tcUtf8.stringReplacements),
            completion(equals(true)),
            reason: '${tcWithoutUtf8.name} (smtpUtf8 false)'));
  }
}
