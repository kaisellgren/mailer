part of message_out_test;

final _dateHeader = 'date: Thu, 31 Mar 2022 00:00:00 \\+0000\r\n';

final messageSimpleUtf8 = MessageTest(
    'Message with utf8 subject, html and text',
    Message()
      ..from = Address('test1@test.com', 'Name')
      ..recipients = ['test2@test.com']
      ..subject = defaultSubject
      ..html = defaultHtml
      ..text = defaultText
      ..headers = {'date': DateTime.utc(2022, 3, 31)},
    mailRegExpTextAndHtml(defaultSubjectRegExpUtf8, dateHeader: _dateHeader),
    mailRegExpTextAndHtml(defaultSubjectRegExpNotUtf8,
        dateHeader: _dateHeader));
