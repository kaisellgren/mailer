part of message_out_test;


final messageSimpleUtf8 = MessageTest(
    'Message with utf8 subject, html and text',
    Message()
      ..from = Address('test1@test.com', 'Name')
      ..recipients = ['test2@test.com']
      ..subject = defaultSubject
      ..html = defaultHtml
      ..text = defaultText,
    mailRegExpTextAndHtml(defaultSubjectRegExpUtf8),
    mailRegExpTextAndHtml(defaultSubjectRegExpNotUtf8));
