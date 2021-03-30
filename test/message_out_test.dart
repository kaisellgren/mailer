import 'dart:convert';

import 'package:mailer/mailer.dart';
import 'package:mailer/src/smtp/capabilities.dart';
import 'package:mailer/src/smtp/internal_representation/internal_representation.dart';

void main() async {
  var message = Message()
    ..from = Address("test1@test.com", "Name")
    ..recipients = ["test2@test.com"]
    ..subject = "utf8 mail😀"
    ..html = "utf8😀h"
    ..text = "utf8😀t";

  var irContent = IRMessage(message);
  var capabilities = capabilitiesForTesting(smtpUtf8: true);
  var data = irContent.data(capabilities);
  var mergedMessage = await data.fold<List<int>>(<int>[], (previous, element) {
    previous.addAll(element);
    return previous;
  });
  var mergedMessageS = utf8.decoder.convert(mergedMessage);
  print(mergedMessageS);
}
