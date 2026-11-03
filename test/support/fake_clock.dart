import 'package:groupay/core/time/clock.dart';

/// A settable clock for repository and widget tests.
final class FakeClock implements Clock {
  FakeClock([this.now = 1000]);

  int now;

  @override
  int nowUtcMillis() => now;
}
