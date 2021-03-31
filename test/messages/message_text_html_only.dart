part of message_out_test;

final messageTextOnly = MessageTest(
    'Message with utf8 subject and text',
    Message()
      ..from = Address('test1@test.com', 'Name')
      ..recipients = ['test2@test.com']
      ..subject = defaultSubject
      ..text = defaultText,
    mailRegExpText(defaultSubjectRegExpUtf8),
    mailRegExpText(defaultSubjectRegExpNotUtf8));

final messageHtmlOnly = MessageTest(
    'Message with utf8 subject and html',
    Message()
          ..from = Address('test1@test.com', 'Name')
          ..recipients = ['test2@test.com']
          ..subject = defaultSubject
          ..html = defaultHtml,
    mailRegExpHtml(defaultSubjectRegExpUtf8),
    mailRegExpHtml(defaultSubjectRegExpNotUtf8));
