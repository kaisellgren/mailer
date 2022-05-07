part of message_out_test;

String e(String stringToEscape) => RegExp.escape(stringToEscape);

const defaultDateHeader =
    'date: [\\w]{3}, [0-9]+ [\\w]{3} 2[0-9]{3} [0-9]{1,2}:[0-9]{2}:[0-9]{2} \\+[0-9]{4}\r\n';
const contentTypeHeaderAlternative =
    'content-type: multipart/alternative;boundary="mailer-\\?=(?<boundaryAlternative>.*)"\r\n';
const boundaryAlternative = '--mailer-\\?=\\k<boundaryAlternative>\r\n';
const boundaryEndAlternative = '--mailer-\\?=\\k<boundaryAlternative>--\r\n';

const contentTypeHeaderMixed =
    'content-type: multipart/mixed;boundary="mailer-\\?=(?<boundaryMixed>.*)"\r\n';
const boundaryMixed = '--mailer-\\?=\\k<boundaryMixed>\r\n';
const boundaryEndMixed = '--mailer-\\?=\\k<boundaryMixed>--\r\n';

const contentTypeHeaderRelated =
    'content-type: multipart/related;boundary="mailer-\\?=(?<boundaryRelated>.*)"\r\n';
const boundaryRelated = '--mailer-\\?=\\k<boundaryRelated>\r\n';
const boundaryEndRelated = '--mailer-\\?=\\k<boundaryRelated>--\r\n';

const defaultSubject = 'utf8 mail😀';
final defaultSubjectRegExpUtf8 = e('utf8 mail😀');
final defaultSubjectRegExpNotUtf8 = e('=?utf-8?B?dXRmOCBtYWls8J+YgA==?=');

final defaultFromRegExp = e('Name <test1@test.com>');

final defaultText = 'utf8😀t';
final defaultHtml = 'utf8😀h';

String mailRegExpTextAndHtml(String subject,
    {String? text, String? html, String? fromHeader, String? dateHeader}) {
  return '^' +
      (dateHeader ??
          '') + // if the date header is specified it comes before the subject.
      'subject: $subject\r\n'
          'from: ${fromHeader ?? defaultFromRegExp}\r\n' +
      e('to: test2@test.com\r\n') +
      (dateHeader != null
          ? ''
          : defaultDateHeader) + // if not the date header comes after the to header
      e('x-mailer: Dart Mailer library\r\n') +
      e('mime-version: 1.0\r\n') +
      contentTypeHeaderAlternative +
      e('\r\n') +
      boundaryAlternative +
      e('content-type: text/plain; charset=utf-8\r\n') +
      e('content-transfer-encoding: base64\r\n') +
      e('\r\n') +
      '${text ?? e('dXRmOPCfmIB0DQo=')}\r\n' +
      e('\r\n') +
      boundaryAlternative +
      e('content-type: text/html; charset=utf-8\r\n') +
      e('content-transfer-encoding: base64\r\n') +
      e('\r\n') +
      '${html ?? e('dXRmOPCfmIBoDQo=')}\r\n' +
      e('\r\n') +
      boundaryEndAlternative +
      e('\r\n') +
      r'$';
}

class TestAttachment {
  final String name;
  final String type;
  final String disposition;
  final String content;

  TestAttachment(this.name, this.type, this.disposition, this.content);
}

String mailRegExpTextHtmlAndInlineAttachments(String subject,
    List<TestAttachment> inlineAttachments, List<TestAttachment> attachments,
    {String? text, String? html, String? fromHeader}) {
  var result = '^'
          'subject: $subject\r\n'
          'from: ${fromHeader ?? defaultFromRegExp}\r\n' +
      e('to: test2@test.com\r\n') +
      defaultDateHeader +
      e('x-mailer: Dart Mailer library\r\n') +
      e('mime-version: 1.0\r\n') +
      contentTypeHeaderMixed +
      e('\r\n') +
      boundaryMixed +
      contentTypeHeaderAlternative +
      e('\r\n') +
      boundaryAlternative +
      e('content-type: text/plain; charset=utf-8\r\n') +
      e('content-transfer-encoding: base64\r\n') +
      e('\r\n') +
      '${text ?? e('dXRmOPCfmIB0DQo=')}\r\n' +
      e('\r\n') +
      boundaryAlternative +
      contentTypeHeaderRelated +
      e('\r\n') +
      boundaryRelated +
      e('content-type: text/html; charset=utf-8\r\n') +
      e('content-transfer-encoding: base64\r\n') +
      e('\r\n') +
      '${html ?? e('dXRmOPCfmIBoDQo=')}\r\n' +
      e('\r\n');
  inlineAttachments.forEach((a) {
    result += boundaryRelated +
        e('content-type: ${a.type}\r\n') +
        e('content-transfer-encoding: base64\r\n') +
        e('content-disposition: ${a.disposition}\r\n') +
        e('\r\n') +
        e('${a.name}\r\n') +
        e('\r\n');
  });
  result += boundaryEndRelated + e('\r\n');
  result += boundaryEndAlternative + e('\r\n');
  attachments.forEach((a) {
    result += boundaryMixed +
        e('content-type: ${a.type}\r\n') +
        e('content-transfer-encoding: base64\r\n') +
        e('content-disposition: ${a.disposition}\r\n') +
        e('\r\n') +
        e('${a.name}\r\n') +
        e('\r\n');
  });

  result += boundaryEndMixed + '\r\n' + r'$';
  return result;
}

String mailRegExpTextOrHtml(String subject,
    {String? text, String? html, String? fromHeader}) {
  return '^'
          'subject: $subject\r\n'
          'from: ${fromHeader ?? defaultFromRegExp}\r\n' +
      e('to: test2@test.com\r\n') +
      defaultDateHeader +
      e('x-mailer: Dart Mailer library\r\n') +
      e('mime-version: 1.0\r\n') +
      e('content-type: text/${text != null ? 'plain' : 'html'}; charset=utf-8\r\n') +
      e('content-transfer-encoding: base64\r\n') +
      e('\r\n') +
      '${text ?? html}\r\n' +
      e('\r\n') +
      r'$';
}

String mailRegExpText(String subject, {String? text, String? fromHeader}) {
  return mailRegExpTextOrHtml(subject, text: text ?? e('dXRmOPCfmIB0DQo='));
}

String mailRegExpHtml(String subject, {String? html, String? fromHeader}) {
  return mailRegExpTextOrHtml(subject, html: html ?? e('dXRmOPCfmIBoDQo='));
}
