import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/ports/payer_usage_port.dart';
import 'package:groupay/core/time/clock.dart';
import 'package:groupay/shell/bootstrap.dart';

import 'fake_clock.dart';
import 'fake_payer_usage.dart';

/// Pumps the whole app, built by `shell/` (`buildGrouPay`) on [db], at
/// [initialLocation].
Future<void> pumpGrouPay(
  WidgetTester tester,
  AppDatabase db, {
  String initialLocation = '/',
  Clock? clock,
  PayerUsagePort? payerUsage,
}) => _pump(
  tester,
  db,
  initialLocation: initialLocation,
  clock: clock,
  payerUsage: payerUsage,
);

/// Launches the app on [db] exactly as `main()` does: the launch location
/// comes from the stored Active group (FR-9).
Future<void> launchGrouPay(WidgetTester tester, AppDatabase db) =>
    _pump(tester, db);

Future<void> _pump(
  WidgetTester tester,
  AppDatabase db, {
  String? initialLocation,
  Clock? clock,
  PayerUsagePort? payerUsage,
}) async {
  final app = await buildGrouPay(
    db,
    clock: clock ?? FakeClock(),
    payerUsage: payerUsage ?? FakePayerUsage(),
    initialLocation: initialLocation,
  );
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// Unmounts the app and lets drift's stream-close timer fire, so no timer
/// is pending when the test ends. Call it at the end of every test that
/// pumped the app.
Future<void> unmountGrouPay(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}
