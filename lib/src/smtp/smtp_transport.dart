part of mailer;

class SmtpTransport extends Transport {
  SmtpOptions options;

  SmtpTransport(this.options) {
    _logger.fine('Tets');
  }

  Future send(Envelope envelope) {
    return new Future(() {
      var completer = new Completer();

      var client = new SmtpClient(options);

      client.send(envelope);

      client.onSend.listen((Envelope mail) {
        if (mail == envelope) {
          completer.complete(true);
        }
      });

      return completer.future;
    });
  }

  Future sendAll(List<Envelope> envelopes) {throw 'Not implemented';}
}