import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/db/database_provider.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ports/port_providers.dart';
import 'package:groupay/core/time/clock_provider.dart';
import 'package:groupay/features/groups/ui/group_list_screen.dart';
import 'package:groupay/shell/app.dart';
import 'package:groupay/shell/overrides.dart';
import 'package:groupay/shell/router.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: appOverrides(database: db),
        child: GrouPayApp(router: buildRouter()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('launches RTL in Hebrew on the empty group list', (tester) async {
    await pumpApp(tester);

    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(find.text(MessageKey.emptyGroupList.text), findsOneWidget);
    expect(find.text(MessageKey.newGroup.text), findsOneWidget);

    final context = tester.element(find.byType(GroupListScreen));
    expect(Directionality.of(context), TextDirection.rtl);
    expect(Localizations.localeOf(context), const Locale('he'));
  });

  testWidgets('tapping "+ קבוצה חדשה" does nothing yet', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text(MessageKey.newGroup.text));
    await tester.pumpAndSettle();
    expect(find.byType(GroupListScreen), findsOneWidget);
  });

  testWidgets('the text scale is clamped to 1.5', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester);

    final context = tester.element(find.byType(GroupListScreen));
    expect(MediaQuery.textScalerOf(context).scale(10), 15);
  });

  testWidgets('the new group button is in the lower half', (tester) async {
    await pumpApp(tester);
    final screen = tester.getSize(find.byType(GroupListScreen));
    final button = tester.getCenter(find.text(MessageKey.newGroup.text));
    expect(button.dy, greaterThan(screen.height / 2));
    // RTL: the primary button sits on the start (right) side.
    expect(button.dx, greaterThan(screen.width / 2));
  });

  test('kernel providers throw until shell binds them', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(appDatabaseProvider), throwsA(anything));
    expect(() => container.read(clockProvider), throwsA(anything));
    expect(() => container.read(payerUsagePortProvider), throwsA(anything));
  });

  test(
    'shell binds the database, a clock and the PayerUsagePort stand-in',
    () async {
      final container = ProviderContainer(
        overrides: appOverrides(database: db),
      );
      addTearDown(container.dispose);
      expect(container.read(appDatabaseProvider), same(db));
      expect(container.read(clockProvider).nowUtcMillis(), greaterThan(0));
      expect(
        await container.read(payerUsagePortProvider).isPayer('g', 'm'),
        isFalse,
      );
    },
  );
}
