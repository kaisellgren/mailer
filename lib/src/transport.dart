part of mailer;

abstract class Transport {
  Future send(Envelope envelope);
}
