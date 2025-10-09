import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../smtp_server.dart';

/// Send through Amazon Simple Email Service (Amazon SES).
///
/// Region is the AWS region, e.g. 'us-east-1', or 'eu-west-1'.
SmtpServer amazon(String accessKeyId, String secretKey, String region) =>
    SmtpServer(
      'email-smtp.$region.amazonaws.com',
      username: accessKeyId,
      password: _smtpPassword(secretKey, region),
    );

Uint8List _sign(Uint8List key, String msg) {
  return Uint8List.fromList(Hmac(sha256, key).convert(utf8.encode(msg)).bytes);
}

String _smtpPassword(String secretKey, String region) {
  // These values are required to calculate the signature. Do not change them.
  const date = '11111111';
  const service = 'ses';
  const message = 'SendRawEmail';
  const terminal = 'aws4_request';
  const version = 0x04;

  var signature = _sign(utf8.encode('AWS4$secretKey'), date);
  signature = _sign(signature, region);
  signature = _sign(signature, service);
  signature = _sign(signature, terminal);
  signature = _sign(signature, message);
  final signatureAndVersion = Uint8List.fromList([version] + signature);
  return base64.encode(signatureAndVersion);
}
