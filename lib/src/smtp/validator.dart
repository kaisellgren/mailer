import 'package:mailer/src/entities/problem.dart';
import 'package:mailer/src/smtp/internal_representation/internal_representation.dart';
import 'package:mailer/src/utils.dart';

import '../entities/address.dart';
import '../entities/message.dart';

bool _printableCharsOnly(String s) {
  return isPrintableRegExp.hasMatch(s);
}

/// [addressIn] can either be an [Address] or String.
bool _validAddress(dynamic addressIn) {
  if (addressIn == null) return false;

  String? address;
  if (addressIn is Address) {
    //Don't validate [Address.name] here since it will be encoded with base64
    //if necessary
    address = addressIn.mailAddress;
  } else {
    address = addressIn as String;
  }
  return _validMailAddress(address);
}

bool _validMailAddress(String ma) {
  var split = ma.split('@');
  return split.length == 2 &&
      split.every((part) => part.isNotEmpty && _printableCharsOnly(part));
}

List<Problem> validate(Message message) {
  var res = <Problem>[];

  void validate(bool isValid, String code, String msg) {
    if (!isValid) {
      res.add(Problem(code, msg));
    }
  }

  validate(
      _validMailAddress(
          message.envelopeFrom ?? message.fromAsAddress.mailAddress),
      'ENV_FROM',
      'Envelope mail address is invalid.  ${message.envelopeFrom}');
  var counter = 0;
  for (var a in (message.envelopeTos ?? <String>[])) {
    counter++;
    validate((a.isNotEmpty), 'ENV_TO_EMPTY',
        'Envelope to address (pos: $counter) is null or empty');
    validate(
        _validMailAddress(a), 'ENV_TO', 'Envelope to address is invalid.  $a');
  }

  validate(_validAddress(message.from), 'FROM_ADDRESS',
      'The from address is invalid.  (${message.from})');
  counter = 0;
  for (var aIn in message.recipients) {
    counter++;
    Address? a;

    a = aIn is String ? Address(aIn) : aIn as Address?;

    validate(
        a != null && (a.mailAddress).isNotEmpty,
        'FROM_ADDRESS_EMPTY',
        'A recipient address is null or empty.  (pos: $counter).');
    if (a != null) {
      validate(_validAddress(a), 'FROM_ADDRESS',
          'A recipient address is invalid.  ($a).');
    }
  }
  try {
    var irMessage = IRMessage(message);
    if (irMessage.envelopeTos.isEmpty) {
      res.add(Problem('NO_RECIPIENTS', 'Mail does not have any recipients.'));
    }
  } on InvalidHeaderException catch (e) {
    res.add(Problem('INVALID_HEADER', e.message));
  } catch (e) {
    res.add(
        Problem('INVALID_MESSAGE', 'Could not build internal representation.'));
  }
  return res;
}
