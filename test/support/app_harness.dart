import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/ports/payer_usage_port.dart';
import 'package:groupay/core/time/clock.dart';
import 'package:groupay/shell/app.dart';
import 'package:groupay/shell/overrides.dart';
import 'package:groupay/shell/router.dart';

import 'fake_clock.dart';
import 'fake_payer_usage.dart';

/// Pumps the whole app, bound by `shell/` to [db].
Future<void> pumpGrouPay(
  WidgetTester tester,
  AppDatabase db, {
  String initialLocation = '/',
  Clock? clock,
  PayerUsagePort? payerUsage,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: appOverrides(
        database: db,
        clock: clock ?? FakeClock(),
        payerUsage: payerUsage ?? FakePayerUsage(),
      ),
      child: GrouPayApp(router: buildRouter(initialLocation: initialLocation)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Unmounts the app and lets drift's stream-close timer fire, so no timer
/// is pending when the test ends. Call it at the end of every test that
/// pumped the app.
Future<void> unmountGrouPay(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}
