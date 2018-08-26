part of 'internal_representation.dart';

Iterable<String> _addressToString(List<Address> addresses) {
  if (addresses == null) return [];
  return addresses.map((a) {
    var fromName = a.name ?? '';
    // ToDo base64 fromName (add _IRMetaInformation as argument)
    return '$fromName <${a.mailAddress}>';
  });
}

int _counter = 0;
var identityString = 'mailer';

String _buildBoundary() =>
    '$identityString-?=_${++_counter}-${new DateTime.now().millisecondsSinceEpoch}';

