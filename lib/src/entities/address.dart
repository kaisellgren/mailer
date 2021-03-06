class Address {
  final String name;
  final String mailAddress;

  const Address([this.mailAddress, this.name]);

  /// The name used to output to SMTP server.
  /// Implementation can override it to pre-process the name before sending.
  /// For example, providing a default name for certain address, or quoting it.
  String get sanitizedName => name;
  /// The address used to output to SMTP server.
  /// Implementation can override it to pre-process the address before sending
  String get sanitizedAddress => mailAddress;

  @override
  String toString() => "${name ?? ''} <$mailAddress>";
}
