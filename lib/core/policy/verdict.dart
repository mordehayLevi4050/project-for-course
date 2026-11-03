import '../i18n/message_key.dart';

/// The answer of a `core/policy` rule (AD-7): allowed, or denied with the
/// message to show.
sealed class Verdict {
  const Verdict();

  bool get isAllowed => this is Allow;
}

final class Allow extends Verdict {
  const Allow();

  @override
  bool operator ==(Object other) => other is Allow;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'Allow';
}

final class Deny extends Verdict {
  const Deny(this.message);

  final MessageKey message;

  @override
  bool operator ==(Object other) => other is Deny && other.message == message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'Deny(${message.name})';
}
