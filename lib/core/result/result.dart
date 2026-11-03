import '../i18n/message_key.dart';

/// The outcome of a repository write (AD-15).
///
/// An expected rejection (validation or policy) is a [Failure] carrying the
/// [MessageKey] to show. Exceptions are reserved for bugs and I/O faults.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.message);

  final MessageKey message;

  @override
  bool operator ==(Object other) =>
      other is Failure<T> && other.message == message;

  @override
  int get hashCode => Object.hash(Failure, message);

  @override
  String toString() => 'Failure(${message.name})';
}
