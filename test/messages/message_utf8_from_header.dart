part of message_out_test;

final _utf8Address = Address('test1@test.com', 'Name😀1');
final _utf8FromHeaderRegexp = e('Name😀1 <test1@test.com>');
final _utf8FromHeaderEncodedRegexp =
    e('=?utf-8?B?TmFtZfCfmIAx?= <test1@test.com>');

final messageUtf8FromHeader = MessageTest(
    'Message with utf8 subject, html and text and utf8 (address) name',
    Message()
      ..from = _utf8Address
      ..recipients = ['test2@test.com']
      ..subject = defaultSubject
      ..html = defaultHtml
      ..text = defaultText,
    mailRegExpTextAndHtml(defaultSubjectRegExpUtf8,
        fromHeader: _utf8FromHeaderRegexp),
    mailRegExpTextAndHtml(defaultSubjectRegExpNotUtf8,
        fromHeader: _utf8FromHeaderEncodedRegexp));
