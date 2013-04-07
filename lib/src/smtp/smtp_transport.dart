part of mailer;

class SmtpTransport extends Transport {
  SmtpOptions options;

  SmtpTransport(this.options);

  Future send(Envelope envelope) {
    return new Future.of(() {
      var client = new SmtpClient(options);

      client.onSend.listen((Envelope mail) {
        print('Sent: ${mail.subject}');
      });

      client.send(envelope);
    });
  }
}