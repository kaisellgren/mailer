part of message_out_test;

final _subjectBelow = 's' + ('\u{1f596}' * 199);
final _subjectAbove = 's' + ('\u{1f596}' * 200);
final _textBody = 't' + ('\u{1f596}' * 300);

final _subjectBelowUtf8RegExp = e(
    '=?utf-8?B?c/Cflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+Wlg==?=');

final _textBodyEncoded = e(
    'dPCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+W\r\n'
    'lvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+W\r\n'
    'lvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+W\r\n'
    'lvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+W\r\n'
    'lvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+W\r\n'
    'lg0K');

final _subjectAboveUtf8RegExp = e(
    '=?utf-8?B?c/Cflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpbwn5aW8J+WlvCflpY=?=\r\n'
    ' =?utf-8?B?8J+WlvCflpY=?=');

final messageUtf8LongSubjectLongBodyBelowLineLength = MessageTest(
    'Message with utf8 subject, html and text',
    Message()
      ..from = Address('test1@test.com', 'Name')
      ..recipients = ['test2@test.com']
      ..subject = _subjectBelow
      ..html = defaultHtml
      ..text = _textBody,
    mailRegExpTextAndHtml(_subjectBelow, text: _textBodyEncoded),
    mailRegExpTextAndHtml(_subjectBelowUtf8RegExp, text: _textBodyEncoded));

final messageUtf8LongSubjectLongBodyAboveLineLength = MessageTest(
    'Message with utf8 subject, html and text',
    Message()
      ..from = Address('test1@test.com', 'Name')
      ..recipients = ['test2@test.com']
      ..subject = _subjectAbove
      ..html = defaultHtml
      ..text = _textBody,
    mailRegExpTextAndHtml(_subjectAboveUtf8RegExp, text: _textBodyEncoded),
    mailRegExpTextAndHtml(_subjectAboveUtf8RegExp, text: _textBodyEncoded));
