import 'package:test/test.dart';
import 'package:mailer/mailer.dart';

void main() {
  final parseMailboxesCases = [
    {
      'test': '',
      'values': <Address>[],
    },
    {
      'test': '  bob@example.com  ',
      'values': [Address('bob@example.com', '')],
    },
    {
      'test': '  <bob@example.com>  ',
      'values': [Address('bob@example.com', '')],
    },
    {
      'test': '  Bob Example    <bob@example.com>   ',
      'values': [Address('bob@example.com', 'Bob Example')],
    },
    {
      'test': ' "  Bob Example  "  <bob@example.com> ',
      'values': [Address('bob@example.com', 'Bob Example')],
    },
    {
      'test': '"Example, Bob J." <bob@example.com>',
      'values': [Address('bob@example.com', 'Example, Bob J.')],
    },
    {
      'test': r'"Example, Robert \"Bob\" \J." <bob@example.com>',
      'values': [Address('bob@example.com', r'Example, Robert "Bob" J.')],
    },
    {
      'test': 'bob@example.com,jim@example.com',
      'values': [
        Address('bob@example.com', ''),
        Address('jim@example.com', '')
      ],
    },
    {
      'test': r'''
        <bob@example.com>, 
        bob2@example.com, 
        Bob Example <bob3@example.com>, 
        "Bob Example" <bob4@example.com>',
        "Example, Robert \"Bob\" \J." <bob5@example.com>
        ''',
      'values': [
        Address('bob@example.com', ''),
        Address('bob2@example.com', ''),
        Address('bob3@example.com', 'Bob Example'),
        Address('bob4@example.com', 'Bob Example'),
        Address('bob5@example.com', r'Example, Robert "Bob" J.'),
      ],
    },
  ];

  for (var t in parseMailboxesCases) {
    test('parseMailboxes: ${t['test']}', () {
      final addresses = parseMailboxes(t['test'] as String);
      final expected = t['values'] as List<Address>;
      expect(addresses.length, expected.length);
      for (var i = 0; i < expected.length; i++) {
        expect(addresses[i].name, expected[i].name, reason: '[$i].name');
        expect(addresses[i].mailAddress, expected[i].mailAddress,
            reason: '[$i].mailAddress');
      }
    });
  }
}
