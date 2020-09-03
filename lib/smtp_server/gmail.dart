import 'dart:convert' show base64, ascii;
import '../smtp_server.dart';

/// Send through gmail with username / password authentication.
///
/// **WARNING** Authentication with username / password is a Less-Secure-App
/// feature, which has been [scheduled for deprecation][1] once.
///
/// [1]: https://gsuiteupdates.googleblog.com/2019/12/less-secure-apps-oauth-google-username-password-incorrect.html
@Deprecated(
  'Favor gmailUserXoauth2 as username/password is considered a Less-Secure-Apps',
)
SmtpServer gmail(String username, String password) =>
    SmtpServer('smtp.gmail.com', username: username, password: password);

@Deprecated('Favor gmailUserXoauth2 or gmailRelayXoauth2')
SmtpServer gmailXoauth2(String token) =>
    SmtpServer('smtp.gmail.com', xoauth2Token: token);

/// Send through gmail with [SASL XOAUTH2][1] authentication.
///
/// This requires an [accessToken] for [userEmail] with the OAuth2 scope:
/// `https://mail.google.com/`.
///
/// [1]: https://developers.google.com/gmail/imap/xoauth2-protocol#the_sasl_xoauth2_mechanism
SmtpServer gmailSaslXoauth2(
  String userEmail,
  String accessToken,
) =>
    SmtpServer(
      'smtp.gmail.com',
      xoauth2Token: _formatXoauth2Token(userEmail, accessToken),
      ssl: true,
      port: 465,
    );

/// Send through GSuite gmail relay with [SASL XOAUTH2][1] authentication.
///
/// This requires that the _G Suite SMTP relay service_ is enabled by the
/// GSuite administrator. For more information see:
/// [Send email from a printer, scanner, or app][2].
///
/// This requires an [accessToken] for [userEmail] with the OAuth2 scope:
/// `https://mail.google.com/`. This can be obtained in many differnet ways,
/// one could add an application to the GSuite account and have users grant
/// access, or one could use [domain-wide delegation][3] to obtain a
/// service-account that can impersonate any GSuite user for the given domain
/// with the `https://mail.google.com/`, and then [use said service account][4]
/// to obtain an `accessToken` impersonating a GSuite user.
///
/// [1]: https://developers.google.com/gmail/imap/xoauth2-protocol#the_sasl_xoauth2_mechanism
/// [2]: https://support.google.com/a/answer/176600?hl=en
/// [3]: https://support.google.com/a/answer/162106?hl=en
/// [4]: https://developers.google.com/identity/protocols/oauth2/service-account#delegatingauthority
SmtpServer gmailRelaySaslXoauth2(
  String userEmail,
  String accessToken,
) =>
    SmtpServer(
      'smtp-relay.gmail.com',
      xoauth2Token: _formatXoauth2Token(userEmail, accessToken),
      ssl: true,
      port: 465,
    );

/// Format in compliance with:
/// https://developers.google.com/gmail/imap/xoauth2-protocol#the_sasl_xoauth2_mechanism
String _formatXoauth2Token(
  String userEmail,
  String accessToken,
) =>
    ascii.fuse(base64).encode(
          'user=$userEmail\u0001auth=Bearer $accessToken\u0001\u0001',
        );
