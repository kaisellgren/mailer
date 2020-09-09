class Address {
  String name;
  String mailAddress;

  const Address([this.mailAddress, this.name]);

  /// Generates an address that must conform to RFC 5322.
  /// For example, `name <foo@domain.com>`, `<foo@domain.com>`
  /// and `foo.domain.com`.
  @override
  String toString() {
    var fromName = name ?? '';
    // ToDo base64 fromName (add _IRMetaInformation as argument)
    return '$fromName <$mailAddress>';
  }
}
