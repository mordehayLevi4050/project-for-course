import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/time/clock.dart';

void main() {
  test('SystemClock returns UTC epoch milliseconds for now', () {
    final before = DateTime.now().toUtc().millisecondsSinceEpoch;
    final now = const SystemClock().nowUtcMillis();
    final after = DateTime.now().toUtc().millisecondsSinceEpoch;
    expect(now, inInclusiveRange(before, after));
  });
}
