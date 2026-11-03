/// The single time source for repositories (AD-8).
abstract interface class Clock {
  /// Now, as UTC epoch milliseconds.
  int nowUtcMillis();
}

/// The device clock.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  int nowUtcMillis() => DateTime.now().toUtc().millisecondsSinceEpoch;
}
