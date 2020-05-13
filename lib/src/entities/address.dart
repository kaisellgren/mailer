class Address {
  String name;
  String mailAddress;

  Address([this.mailAddress, this.name]);

  @override
  String toString() {
    var fromName = name ?? '';
    // ToDo base64 fromName (add _IRMetaInformation as argument)
    return '$fromName <$mailAddress>';
  }
}
