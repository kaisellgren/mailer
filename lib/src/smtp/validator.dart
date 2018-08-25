import '../entities/address.dart';
import '../entities/message.dart';
import '../entities/problem.dart';

// https://stackoverflow.com/questions/12052825/regular-expression-for-all-printable-characters-in-javascript
final RegExp _printableCharsRegExp =
    new RegExp(r'^[\u0020-\u007e\u00a0-\u00ff]*$');

bool _printableCharsOnly(String s) {
  return _printableCharsRegExp.hasMatch(s);
}

bool _validAddress(Address address) {
  if (address == null) return false;
  return _printableCharsOnly(address.name ?? '') &&
      _validMailAddress(address.mailAddress);
}

bool _validMailAddress(String ma) {
  var split = ma.split('@');
  return split.length == 2 &&
      split.every((part) => part.isNotEmpty && _printableCharsOnly(part));
}

List<Problem> validate(Message mail) {
  List<Problem> res = <Problem>[];

  var validate = (bool isValid, String code, String msg) {
    if (!isValid) {
      res.add(new Problem(code, msg));
    }
  };

  validate(_validMailAddress(mail.envelopeFrom ?? ''), 'ENV_FROM',
      'Envelope mail address is invalid.  ${mail.envelopeFrom}');
  int counter = 0;
  (mail.envelopeTos ?? <String>[]).forEach((a) {
    counter++;
    validate((a != null && a.isNotEmpty), 'ENV_TO_EMPTY',
        'Envelope to address (pos: $counter) is null or empty');
    validate(
        _validMailAddress(a), 'ENV_TO', 'Envelope to address is invalid.  $a');
  });

  validate(_validAddress(mail.from), 'FROM_ADDRESS',
      'The from address is invalid.  (${mail.from})');
  counter = 0;
  mail.recipients.forEach((a) {
    counter++;
    validate(
        a != null && (a.mailAddress ?? '').isNotEmpty,
        'FROM_ADDRESS_EMPTY',
        'A recipient address is null or empty.  (pos: $counter).');
    if (a != null) {
      validate(_validAddress(a), 'FROM_ADDRESS',
          'A recipient address is invalid.  ($a).');
    }
  });
  return res;
}
