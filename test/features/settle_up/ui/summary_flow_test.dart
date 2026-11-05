import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/core/ui/theme/tokens.dart';
import 'package:groupay/core/ui/widgets/category_stripe.dart';
import 'package:groupay/core/ui/widgets/group_header.dart';
import 'package:groupay/features/expenses/data/drift_expense_repository.dart';
import 'package:groupay/features/expenses/data/drift_payer_usage.dart';
import 'package:groupay/features/expenses/domain/category.dart';
import 'package:groupay/features/expenses/domain/expense.dart';
import 'package:groupay/features/expenses/ui/group_page.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/member.dart';
import 'package:groupay/features/settle_up/ui/summary_screen.dart';
import 'package:groupay/features/settle_up/ui/transfer_card.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_clock.dart';
import '../../../support/heebo.dart';

/// Story 1.4 part A: the Summary (FR-16) and its "סיכום" button, with the
/// Transfers of the `settle_up` calculation (FR-15) kept live.
void main() {
  late AppDatabase db;
  late FakeClock clock;
  late DriftGroupRepository groups;
  late DriftMemberRepository members;
  late DriftExpenseRepository expenses;

  setUpAll(loadHeebo);

  setUp(() {
    db = AppDatabase.memory();
    clock = FakeClock(DateTime.utc(2026, 12, 14, 10).millisecondsSinceEpoch);
    groups = DriftGroupRepository(db, clock);
    members = DriftMemberRepository(db, clock, DriftPayerUsage(db));
    expenses = DriftExpenseRepository(db, clock, members);
  });
  tearDown(() => db.close());

  /// A widget test that always unmounts the app, even after a failed
  /// expectation, so no drift timer is left pending.
  void appTest(String description, Future<void> Function(WidgetTester) body) =>
      testWidgets(description, (tester) async {
        try {
          await body(tester);
        } finally {
          await unmountGrouPay(tester);
        }
      });

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<(String, Map<String, Member>)> seed(
    List<String> names, {
    String group = 'Budapest',
  }) async {
    final g =
        (await groups.createGroup(id: newId(), name: group) as Ok<Group>).value;
    final byName = <String, Member>{};
    for (final n in names) {
      byName[n] = (await members.addMember(
        id: newId(),
        groupId: g.id,
        name: n,
      ) as Ok<Member>).value;
    }
    return (g.id, byName);
  }

  Future<Expense> record(String groupId, Member payer, int tenths) async =>
      (await expenses.add(
        id: newId(),
        groupId: groupId,
        payerId: payer.id,
        amount: Tenths(tenths),
        category: Category.hotel,
      ) as Ok<Expense>).value;

  Future<void> open(WidgetTester tester, String location) async {
    usePhone(tester);
    await pumpGrouPay(tester, db, initialLocation: location, clock: clock);
  }

  String strip(String s) => s.replaceAll(RegExp('[\u2066-\u2069]'), '');

  /// A Text that reads [text] once the bidi isolates are removed.
  Finder readsAs(String text) => find.byWidgetPredicate(
    (w) => w is Text && w.data != null && strip(w.data!) == text,
  );

  /// The category share stripes inside the Summary header.
  Finder headerStripe() => find.descendant(
    of: find.byType(GroupHeader),
    matching: find.byType(CategoryStripe),
  );

  /// Each card as the reader sees it: "sentence ₪N".
  List<String> lines(WidgetTester tester) => [
    for (final card in tester.widgetList<TransferCard>(
      find.byType(TransferCard),
    ))
      [
        for (final t in tester.widgetList<Text>(
          find.descendant(of: find.byWidget(card), matching: find.byType(Text)),
        ))
          t.data!,
      ].skip(2).map(strip).join(' '),
  ];

  Finder summaryButton() =>
      find.widgetWithText(OutlinedButton, MessageKey.summaryButton.text);

  appTest('T3.2: below two Members "סיכום" is at 40% and does nothing', (
    tester,
  ) async {
    final (g, _) = await seed(['Dana']);
    await open(tester, '/group/$g');
    expect(summaryButton(), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: summaryButton(), matching: find.byType(Opacity)).first,
    );
    expect(opacity.opacity, AppOpacity.disabled);
    expect(tester.widget<OutlinedButton>(summaryButton()).onPressed, isNull);
    await tester.tap(summaryButton(), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.byType(SummaryScreen), findsNothing);
  });

  appTest('a typed Summary route below two Members shows the hint', (
    tester,
  ) async {
    final (g, _) = await seed(['Dana']);
    await open(tester, '/group/$g/summary');
    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text(MessageKey.needTwoMembers.text), findsOneWidget);
    expect(find.byType(TransferCard), findsNothing);
  });

  appTest('T3.43: "סיכום" opens the Summary; "→ חזרה" goes back', (
    tester,
  ) async {
    final (g, m) = await seed(['דנה', 'יוסי', 'נועה']);
    await record(g, m['דנה']!, 3000);
    await open(tester, '/group/$g');
    // "סיכום" is on the end (left) side, about a third of the width.
    final button = tester.getRect(summaryButton());
    final width = tester.getSize(find.byType(GroupPage)).width;
    expect(button.left, lessThan(width / 4));
    expect(button.width, closeTo(width / 3, width / 8));

    await tester.tap(summaryButton());
    await tester.pumpAndSettle();
    expect(find.byType(SummaryScreen), findsOneWidget);
    expect(find.text('Budapest'), findsOneWidget);
    expect(find.text(MessageKey.transfersTitle.text), findsOneWidget);
    // T3.7: the header holds the Trip total and the one-Category stripe.
    expect(
      find.descendant(of: find.byType(GroupHeader), matching: readsAs('₪300')),
      findsOneWidget,
    );
    expect(headerStripe(), findsOneWidget);
    expect(
      tester.widget<CategoryStripe>(headerStripe()).segments,
      hasLength(1),
    );
    expect(find.text(MessageKey.groupSettingsChip.text), findsNothing);
    expect(find.text(strip(MessageKey.groupSettingsChip.text)), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Text &&
            w.data != null &&
            strip(w.data!) == '3 משתתפים · ₪100 לאחד',
      ),
      findsOneWidget,
    );
    expect(lines(tester), [
      'תשלום נדרש מיוסי לדנה ₪100',
      'תשלום נדרש מנועה לדנה ₪100',
    ]);

    // The cards are flat and not tappable.
    expect(
      find.descendant(
        of: find.byType(TransferCard),
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector || w is InkWell,
        ),
      ),
      findsNothing,
    );

    await tester.tap(find.text(MessageKey.summaryNav.text));
    await tester.pumpAndSettle();
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.byType(SummaryScreen), findsNothing);
  });

  appTest('T3.44: Latin names get a hyphen, word order intact', (tester) async {
    final (g, m) = await seed(['Zoe', 'Adam', 'דנה']);
    await record(g, m['Zoe']!, 3000);
    await open(tester, '/group/$g/summary');
    expect(lines(tester), [
      'תשלום נדרש מדנה ל-Zoe ₪100',
      'תשלום נדרש מ-Adam ל-Zoe ₪100',
    ]);
  });

  appTest('T3.3 / T3.15: settled Groups show the fixed message', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi', 'Noa']);
    await record(g, m['Dana']!, 334);
    await record(g, m['Yossi']!, 333);
    await record(g, m['Noa']!, 333);
    await open(tester, '/group/$g/summary');
    expect(find.text(MessageKey.settledUp.text), findsOneWidget);
    expect(find.byType(TransferCard), findsNothing);
  });

  appTest('T3.8: 6 Members and 5 Transfers fit one screen, no scroll', (
    tester,
  ) async {
    // Typical names; whether 5 wrapped long-name lines fit is the open
    // on-device check (EXPERIENCE.md OQ1), set aside for now.
    final (g, m) = await seed(['מוטי', 'דנה', 'יוסי', 'נועה', 'Adam', 'Zoe']);
    await record(g, m['Zoe']!, 123456);
    await open(tester, '/group/$g/summary');
    expect(find.byType(TransferCard), findsNWidgets(5));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SummaryScreen),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, 0);
    final screen = tester.getSize(find.byType(SummaryScreen));
    for (final card in tester.widgetList(find.byType(TransferCard))) {
      expect(
        tester.getRect(find.byWidget(card)).bottom,
        lessThan(screen.height),
      );
    }

    // No arrow or other direction symbol anywhere in the cards.
    final arrows = RegExp('[\u2190-\u21FF\u2794-\u27BF\u2B00-\u2BFF<>]');
    for (final t in tester.widgetList<Text>(
      find.descendant(
        of: find.byType(TransferCard),
        matching: find.byType(Text),
      ),
    )) {
      expect(arrows.hasMatch(t.data!), isFalse, reason: t.data);
    }
    expect(tester.takeException(), isNull);
  });

  appTest('T1.20 / T1.13 / T2.16 / T1.12 / T1.17: the Summary stays live', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    final expense = await record(g, m['Dana']!, 3000);
    await open(tester, '/group/$g/summary');
    expect(lines(tester), ['תשלום נדרש מ-Yossi ל-Dana ₪150']);

    // T1.20: adding Noa splits the Expense three ways.
    final noa = (await tester.runAsync(
      () => members.addMember(id: newId(), groupId: g, name: 'Noa'),
    ) as Ok<Member>).value;
    await tester.pumpAndSettle();
    expect(lines(tester), [
      'תשלום נדרש מ-Noa ל-Dana ₪100',
      'תשלום נדרש מ-Yossi ל-Dana ₪100',
    ]);

    // T2.16: editing ₪300 to ₪150.
    await tester.runAsync(
      () => expenses.update(
        id: expense.id,
        payerId: m['Dana']!.id,
        amount: const Tenths(1500),
        category: Category.hotel,
      ),
    );
    await tester.pumpAndSettle();
    expect(lines(tester), [
      'תשלום נדרש מ-Noa ל-Dana ₪50',
      'תשלום נדרש מ-Yossi ל-Dana ₪50',
    ]);
    expect(readsAs('₪150'), findsOneWidget);
    expect(readsAs('3 משתתפים · ₪50 לאחד'), findsOneWidget);

    // T1.12: renaming Dana keeps the amounts.
    await tester.runAsync(
      () => members.renameMember(id: m['Dana']!.id, name: 'Danna'),
    );
    await tester.pumpAndSettle();
    expect(lines(tester), [
      'תשלום נדרש מ-Noa ל-Danna ₪50',
      'תשלום נדרש מ-Yossi ל-Danna ₪50',
    ]);

    // T1.13: removing Noa splits it two ways again.
    await tester.runAsync(() => members.removeMember(id: noa.id));
    await tester.pumpAndSettle();
    expect(lines(tester), ['תשלום נדרש מ-Yossi ל-Danna ₪75']);

    // T1.17: the header follows a Group rename.
    await tester.runAsync(
      () => groups.renameGroup(id: g, name: 'Budapest 2026'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Budapest 2026'), findsOneWidget);
  });

  appTest('an Archived group\'s Summary route opens its read-only page', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 3000);
    await groups.archive(id: g);
    await open(tester, '/group/$g/summary');
    expect(find.byType(SummaryScreen), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.text(MessageKey.archivedBadge.text), findsOneWidget);
  });
}
