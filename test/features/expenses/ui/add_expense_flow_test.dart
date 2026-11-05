import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/money/format_shekel.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/core/ui/theme/tokens.dart';
import 'package:groupay/core/ui/widgets/category_stripe.dart';
import 'package:groupay/core/ui/widgets/group_header.dart';
import 'package:groupay/core/ui/widgets/member_avatar.dart';
import 'package:groupay/features/expenses/data/drift_expense_repository.dart';
import 'package:groupay/features/expenses/data/drift_payer_usage.dart';
import 'package:groupay/features/expenses/domain/category.dart';
import 'package:groupay/features/expenses/ui/add_expense_screen.dart';
import 'package:groupay/features/expenses/ui/category_style.dart';
import 'package:groupay/features/expenses/ui/expense_list.dart';
import 'package:groupay/features/expenses/ui/group_page.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/member.dart';
import 'package:groupay/features/groups/ui/group_card.dart';
import 'package:groupay/features/groups/ui/group_list_screen.dart';
import 'package:groupay/features/groups/ui/group_settings_screen.dart';
import 'package:groupay/features/groups/ui/member_list.dart';
import 'package:groupay/shell/bootstrap.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_clock.dart';
import '../../../support/heebo.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;

  setUp(() {
    db = AppDatabase.memory();
    // 14 Dec 2026, 14:32 local.
    clock = FakeClock(
      DateTime(2026, 12, 14, 14, 32).toUtc().millisecondsSinceEpoch,
    );
  });
  tearDown(() => db.close());

  /// A 360×780dp phone (the DESIGN.md reference width).
  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// Seeds a Group with [names] (in add order) and returns its id and
  /// Members by name.
  Future<(String, Map<String, Member>)> seed(
    List<String> names, {
    String name = 'Budapest',
  }) async {
    final group = await DriftGroupRepository(
      db,
      clock,
    ).createGroup(id: newId(), name: name) as Ok<Group>;
    final repo = DriftMemberRepository(db, clock, DriftPayerUsage(db));
    final byName = <String, Member>{};
    for (final n in names) {
      final r = await repo.addMember(
        id: newId(),
        groupId: group.value.id,
        name: n,
      ) as Ok<Member>;
      byName[n] = r.value;
    }
    return (group.value.id, byName);
  }

  Future<void> record(
    String groupId,
    Member payer,
    int tenths,
    Category category,
  ) =>
      DriftExpenseRepository(
        db,
        clock,
        DriftMemberRepository(db, clock, DriftPayerUsage(db)),
      ).add(
        id: newId(),
        groupId: groupId,
        payerId: payer.id,
        amount: Tenths(tenths),
        category: category,
      );

  Future<void> openGroup(WidgetTester tester, String groupId) async {
    usePhone(tester);
    await pumpGrouPay(
      tester,
      db,
      initialLocation: '/group/$groupId',
      clock: clock,
    );
    expect(find.byType(GroupPage), findsOneWidget);
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openAdd(WidgetTester tester) async {
    await tapAndSettle(tester, find.text(MessageKey.addExpense.text));
    expect(find.byType(AddExpenseScreen), findsOneWidget);
  }

  Future<void> type(WidgetTester tester, String amount) async {
    for (final ch in amount.split('')) {
      final name = ch == '.' ? 'decimalPoint' : 'digit$ch';
      await tester.tap(find.byKey(ValueKey('keypad-$name')));
      await tester.pump();
    }
  }

  Future<void> backspace(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('keypad-backspace')));
    await tester.pump();
  }

  Finder tile(Category c) => find.byKey(ValueKey('category-${c.key}'));

  Future<void> pick(WidgetTester tester, Category c) =>
      tapAndSettle(tester, tile(c));

  Future<void> save(WidgetTester tester) =>
      tapAndSettle(tester, find.text(MessageKey.save.text));

  String amountText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('amount-text'))).data!;

  String slot(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('amount-message'))).data!;

  bool? payerSelected(WidgetTester tester, Member m) => tester
      .widget<MemberAvatar>(
        find.descendant(
          of: find.byKey(ValueKey('payer-${m.id}')),
          matching: find.byType(MemberAvatar),
        ),
      )
      .selected;

  Future<List<ExpenseRow>> rows() => db.select(db.expenses).get();

  Finder sheetText(String text) =>
      find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

  testWidgets('Dana, 300, 🏨, Save: back on the Group page with the row', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi', 'Noa']);
    await openGroup(tester, g);
    expect(find.text(MessageKey.noExpenses.text), findsOneWidget);
    expect(find.text(formatShekel(Tenths.zero)), findsOneWidget);
    expect(find.text('3 משתתפים · 0 הוצאות'), findsOneWidget);

    // The primary sits in the lower half, on the start (right) side.
    final screen = tester.getSize(find.byType(GroupPage));
    final add = tester.getCenter(find.text(MessageKey.addExpense.text));
    expect(add.dy, greaterThan(screen.height / 2));
    expect(add.dx, greaterThan(screen.width / 2));

    await openAdd(tester);
    // Initial: empty Amount, the default Payer, no Category, no message.
    expect(amountText(tester), '');
    expect(slot(tester), '');
    expect(payerSelected(tester, m['Dana']!), isTrue);
    expect(payerSelected(tester, m['Yossi']!), isFalse);
    expect(find.byKey(const ValueKey('category-pages')), findsNothing);

    await type(tester, '300');
    await pick(tester, Category.hotel);
    await tester.tap(find.text(MessageKey.save.text));
    // The new row slides in at the top.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.byType(GroupPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ExpenseList),
        matching: find.byType(SizeTransition),
      ),
      findsOneWidget,
    );
    await tester.pumpAndSettle();

    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(find.text(MessageKey.noExpenses.text), findsNothing);
    expect(find.text(MessageKey.categoryHotel.text), findsOneWidget);
    // Header total and row amount.
    expect(find.text(formatShekel(const Tenths(3000))), findsNWidgets(2));
    expect(find.text('3 משתתפים · הוצאה אחת'), findsOneWidget);
    expect(find.textContaining('14:32'), findsOneWidget);
    expect(find.textContaining('Dana'), findsOneWidget);

    final saved = (await rows()).single;
    expect(saved.payerId, m['Dana']!.id);
    expect(saved.amount, 3000);
    expect(saved.category, 'hotel');

    // The group-list card shows the same total.
    await tapAndSettle(tester, find.text(MessageKey.groupListNav.text));
    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(find.text(formatShekel(const Tenths(3000))), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('Save twice quickly: exactly one Expense', (tester) async {
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await type(tester, '300');
    await pick(tester, Category.hotel);
    await tester.tap(find.text(MessageKey.save.text));
    await tester.tap(find.text(MessageKey.save.text), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(GroupPage), findsOneWidget);
    expect(await rows(), hasLength(1));
    await unmountGrouPay(tester);
  });

  testWidgets('bad Amounts are refused; Payer and Category stay', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await tapAndSettle(tester, find.byKey(ValueKey('payer-${m['Yossi']!.id}')));
    await pick(tester, Category.hotel);

    // Empty.
    await save(tester);
    expect(slot(tester), MessageKey.invalidAmount.text);
    expect(find.byType(AddExpenseScreen), findsOneWidget);

    // The message clears on the next Amount change.
    await type(tester, '0');
    expect(slot(tester), '');
    await save(tester);
    expect(slot(tester), MessageKey.invalidAmount.text);

    await backspace(tester);
    await type(tester, '1000001');
    await save(tester);
    expect(slot(tester), MessageKey.invalidAmount.text);
    expect(await rows(), isEmpty);
    expect(payerSelected(tester, m['Yossi']!), isTrue);

    // Fixing the Amount saves with the kept Payer and Category.
    await backspace(tester);
    await save(tester);
    expect(find.byType(GroupPage), findsOneWidget);
    final saved = (await rows()).single;
    expect(saved.amount, 1000000);
    expect(saved.payerId, m['Yossi']!.id);
    expect(saved.category, 'hotel');
    await unmountGrouPay(tester);
  });

  testWidgets('₪1,000,000 is saved', (tester) async {
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await type(tester, '1000000');
    await pick(tester, Category.hotel);
    await save(tester);
    expect((await rows()).single.amount, 10000000);
    await unmountGrouPay(tester);
  });

  testWidgets('typing 87.45 shows 87.4; no Category is refused', (
    tester,
  ) async {
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await type(tester, '87.45');
    expect(amountText(tester), '87.4');
    await type(tester, '.');
    expect(amountText(tester), '87.4');

    await save(tester);
    expect(slot(tester), MessageKey.chooseCategory.text);
    expect(await rows(), isEmpty);
    await pick(tester, Category.foodDrink);
    expect(slot(tester), '');
    await unmountGrouPay(tester);
  });

  testWidgets('"." on an empty Amount enters "0."', (tester) async {
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await type(tester, '.5');
    expect(amountText(tester), '0.5');
    await unmountGrouPay(tester);
  });

  testWidgets('Other needs a Description; "Umbrella" titles the row', (
    tester,
  ) async {
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await type(tester, '50');
    await pick(tester, Category.other);

    final field = find.byKey(const ValueKey('description-field'));
    expect(field, findsOneWidget);
    expect(find.text(MessageKey.descriptionHint.text), findsOneWidget);
    expect(find.byKey(const ValueKey('keypad-digit1')), findsNothing);

    await tester.enterText(field, '  ');
    await save(tester);
    expect(slot(tester), MessageKey.descriptionRequired.text);
    expect(await rows(), isEmpty);
    expect(amountText(tester), '50');

    // Switching away hides the field but keeps its text.
    await tester.enterText(field, 'Umbrella');
    await pick(tester, Category.car);
    expect(field, findsNothing);
    expect(find.byKey(const ValueKey('keypad-digit1')), findsOneWidget);
    await pick(tester, Category.other);
    expect(find.text('Umbrella'), findsOneWidget);

    await save(tester);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.text('Umbrella'), findsOneWidget);
    expect((await rows()).single.description, 'Umbrella');
    await unmountGrouPay(tester);
  });

  testWidgets('a Description typed under Other is not stored for Car', (
    tester,
  ) async {
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await type(tester, '50');
    await pick(tester, Category.other);
    await tester.enterText(
      find.byKey(const ValueKey('description-field')),
      'Umbrella',
    );
    await pick(tester, Category.car);
    await save(tester);
    expect((await rows()).single.description, isNull);
    await unmountGrouPay(tester);
  });

  testWidgets('the default Payer is the last Payer, then the earliest', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Motty', 'Yossi']);
    await record(g, m['Yossi']!, 10, Category.car);
    await record(g, m['Motty']!, 10, Category.car);
    await openGroup(tester, g);
    await openAdd(tester);
    expect(payerSelected(tester, m['Motty']!), isTrue);
    expect(payerSelected(tester, m['Dana']!), isFalse);

    // A changed Payer becomes the next default.
    await tapAndSettle(tester, find.byKey(ValueKey('payer-${m['Dana']!.id}')));
    await type(tester, '200');
    await pick(tester, Category.fuel);
    await save(tester);
    await openAdd(tester);
    expect(payerSelected(tester, m['Dana']!), isTrue);
    await unmountGrouPay(tester);
  });

  testWidgets('no Expenses: the earliest-added Member is the Payer', (
    tester,
  ) async {
    final (g, m) = await seed(['Motty', 'Dana']);
    await openGroup(tester, g);
    await openAdd(tester);
    expect(payerSelected(tester, m['Motty']!), isTrue);
    await unmountGrouPay(tester);
  });

  testWidgets('leaving with 87 typed goes through the Exit sheet', (
    tester,
  ) async {
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await type(tester, '87');

    // ✕ → sheet → "המשך עריכה" keeps 87.
    await tapAndSettle(tester, find.text(MessageKey.close.text));
    expect(find.text(MessageKey.exitTitle.text), findsOneWidget);
    expect(find.text(MessageKey.exitBody.text), findsOneWidget);
    await tapAndSettle(tester, sheetText(MessageKey.keepEditing.text));
    expect(find.byType(BottomSheet), findsNothing);
    expect(amountText(tester), '87');

    // Back → sheet → scrim keeps 87.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(MessageKey.exitTitle.text), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(amountText(tester), '87');

    // Back → sheet → back keeps 87.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(AddExpenseScreen), findsOneWidget);
    expect(amountText(tester), '87');

    // Back → sheet → "יציאה" leaves with nothing saved.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapAndSettle(tester, sheetText(MessageKey.exitConfirm.text));
    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(await rows(), isEmpty);
    await unmountGrouPay(tester);
  });

  testWidgets('with no input, ✕ and back close at once with no sheet', (
    tester,
  ) async {
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await tapAndSettle(tester, find.text(MessageKey.close.text));
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);

    await openAdd(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('a selected Category or changed Payer is unsaved input', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);
    await pick(tester, Category.car);
    await tapAndSettle(tester, find.text(MessageKey.close.text));
    expect(find.text(MessageKey.exitTitle.text), findsOneWidget);
    await tapAndSettle(tester, sheetText(MessageKey.exitConfirm.text));

    await openAdd(tester);
    await tapAndSettle(tester, find.byKey(ValueKey('payer-${m['Yossi']!.id}')));
    await tapAndSettle(tester, find.text(MessageKey.close.text));
    expect(find.text(MessageKey.exitTitle.text), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('fewer than two Members: Add is disabled, with the note', (
    tester,
  ) async {
    final (g, _) = await seed(['Dana']);
    await openGroup(tester, g);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, MessageKey.addExpense.text),
    );
    expect(button.onPressed, isNull);
    final note = find.text(MessageKey.needTwoMembers.text);
    expect(note, findsOneWidget);
    // Directly above the bar.
    expect(
      tester.getBottomLeft(note).dy,
      lessThan(tester.getTopLeft(find.text(MessageKey.addExpense.text)).dy),
    );
    await tester.tap(find.text(MessageKey.addExpense.text));
    await tester.pumpAndSettle();
    expect(find.byType(AddExpenseScreen), findsNothing);
    await unmountGrouPay(tester);
  });

  testWidgets('an Archived group shows its Expenses; add redirects', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 3000, Category.hotel);
    await DriftGroupRepository(db, clock).archive(id: g);
    usePhone(tester);

    await pumpGrouPay(tester, db, initialLocation: '/group/$g/add');
    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.text(MessageKey.archiveNote.text), findsOneWidget);
    expect(find.text(MessageKey.addExpense.text), findsNothing);
    expect(find.text(MessageKey.categoryHotel.text), findsOneWidget);
    expect(find.text(formatShekel(const Tenths(3000))), findsNWidgets(2));
    await unmountGrouPay(tester);
  });

  testWidgets('removing a Member who paid is refused inline', (tester) async {
    final (g, m) = await seed(['Dana', 'Yossi', 'Noa']);
    await record(g, m['Yossi']!, 500, Category.fuel);
    await openGroup(tester, g);
    await tapAndSettle(tester, find.text(MessageKey.groupSettingsChip.text));
    expect(find.byType(GroupSettingsScreen), findsOneWidget);

    await tapAndSettle(
      tester,
      find.descendant(
        of: find.widgetWithText(MemberListRow, 'Yossi'),
        matching: find.text(MessageKey.removeGlyph.text),
      ),
    );
    await tapAndSettle(tester, sheetText(MessageKey.removeMemberConfirm.text));
    expect(find.text(MessageKey.memberIsPayer.text), findsOneWidget);
    expect(find.widgetWithText(MemberListRow, 'Yossi'), findsOneWidget);
    expect(await db.select(db.members).get(), hasLength(3));
    await unmountGrouPay(tester);
  });

  testWidgets('at text scale 1.5 the Group page nav grows and is not clipped', (
    tester,
  ) async {
    await loadHeebo();
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    expect(tester.takeException(), isNull);

    final header = tester.getRect(find.byType(GroupHeader));
    final icon = find.descendant(
      of: find.byType(GroupHeader),
      matching: find.byIcon(Icons.chevron_right),
    );
    final iconRect = tester.getRect(icon);
    final label = tester.getRect(find.text(MessageKey.groupListNav.text));
    expect(iconRect.height, AppTextStyles.headerSecondary.fontSize! * 1.5);
    for (final r in [iconRect, label]) {
      expect(header.contains(r.topLeft), isTrue);
      expect(header.contains(r.bottomRight - const Offset(1, 1)), isTrue);
    }
    // The chevron is on the start (right) side of the label.
    expect(iconRect.left, greaterThanOrEqualTo(label.right));
    await unmountGrouPay(tester);
  });

  testWidgets('at text scale 1.5 the Categories use the two-page row', (
    tester,
  ) async {
    // Real Heebo metrics: the square test font is far wider.
    await loadHeebo();
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    await openAdd(tester);

    final pages = find.byKey(const ValueKey('category-pages'));
    expect(pages, findsOneWidget);
    // Page 1 holds the first four; page 2 starts beyond it, on the left.
    final flight = tester.getRect(tile(Category.flight));
    final restaurant = tester.getRect(tile(Category.restaurant));
    expect(restaurant.right, lessThan(flight.left));
    // The first tile of page 2 peeks in at the left edge.
    expect(restaurant.right, greaterThan(0));
    // Nothing above the keypad is pushed under it.
    expect(
      tester.getRect(pages).bottom,
      lessThan(tester.getRect(find.byKey(const ValueKey('keypad-digit1'))).top),
    );

    await type(tester, '87.4');
    // One swipe (RTL: page 2 is on the left) snaps to page 2.
    await tester.fling(pages, const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(tester.getRect(tile(Category.foodDrink)).center.dx, greaterThan(0));
    await pick(tester, Category.foodDrink);
    expect(find.byKey(const ValueKey('keypad-digit1')), findsOneWidget);
    await save(tester);
    expect((await rows()).single.category, 'food_drink');
    await unmountGrouPay(tester);
  });

  testWidgets('launch → 87.4 🛒 saved in at most 4 taps', (tester) async {
    final (g, _) = await seed(['Motty', 'Dana', 'Yossi']);
    await DriftGroupRepository(db, clock).setActive(id: g);
    usePhone(tester);
    await launchGrouPay(tester, db, clock: clock);
    expect(find.byType(GroupPage), findsOneWidget);

    var taps = 0;
    Future<void> countedTap(Finder f) async {
      taps++;
      await tapAndSettle(tester, f);
    }

    await countedTap(find.text(MessageKey.addExpense.text));
    await type(tester, '87.4'); // typing the Amount does not count
    await countedTap(tile(Category.foodDrink));
    await countedTap(find.text(MessageKey.save.text));

    expect(taps, lessThanOrEqualTo(4));
    expect(find.byType(GroupPage), findsOneWidget);
    final saved = (await rows()).single;
    expect(saved.amount, 874);
    expect(saved.category, 'food_drink');
    expect(find.text(MessageKey.categoryFoodDrink.text), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('an archived card in Archive shows its Trip total', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 874, Category.foodDrink);
    await DriftGroupRepository(db, clock).archive(id: g);
    usePhone(tester);
    await pumpGrouPay(tester, db, initialLocation: '/archive');
    expect(
      find.descendant(
        of: find.byType(ArchivedGroupCard),
        matching: find.text(formatShekel(const Tenths(874))),
      ),
      findsOneWidget,
    );
    await unmountGrouPay(tester);
  });

  testWidgets('the share stripe: one segment per Category, 3:1', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    // Saved car first: the stripe still follows the fixed Category order.
    await record(g, m['Dana']!, 1000, Category.car);
    await record(g, m['Dana']!, 3000, Category.hotel);
    await openGroup(tester, g);

    final stripe = tester.widget<CategoryStripe>(find.byType(CategoryStripe));
    expect(stripe.segments, [
      (color: categoryColor(Category.hotel), weight: 3000),
      (color: categoryColor(Category.car), weight: 1000),
    ]);

    final boxes = find.descendant(
      of: find.byType(CategoryStripe),
      matching: find.byType(DecoratedBox),
    );
    expect(boxes, findsNWidgets(2));
    final colors = [
      for (final box in tester.widgetList<DecoratedBox>(boxes))
        (box.decoration as BoxDecoration).color,
    ];
    expect(colors, [
      categoryColor(Category.hotel),
      categoryColor(Category.car),
    ]);
    final hotel = tester.getSize(boxes.at(0)).width;
    final car = tester.getSize(boxes.at(1)).width;
    expect(hotel / car, closeTo(3, 0.01));
    // RTL: the first segment sits on the start (right) side.
    expect(
      tester.getCenter(boxes.at(0)).dx,
      greaterThan(tester.getCenter(boxes.at(1)).dx),
    );
    await unmountGrouPay(tester);
  });

  testWidgets('rows already there on opening do not slide in', (tester) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 3000, Category.hotel);
    usePhone(tester);
    await tester.pumpWidget(
      await buildGrouPay(db, clock: clock, initialLocation: '/group/$g'),
    );
    final slides = find.descendant(
      of: find.byType(ExpenseList),
      matching: find.byType(SizeTransition),
    );
    // Pump until the first Expenses arrive, one frame at a time.
    for (
      var i = 0;
      i < 10 && find.byType(ExpenseRowCard).evaluate().isEmpty;
      i++
    ) {
      await tester.pump();
    }
    expect(find.byType(ExpenseRowCard), findsOneWidget);
    expect(slides, findsNothing);
    await tester.pump();
    expect(slides, findsNothing);
    await unmountGrouPay(tester);
  });

  testWidgets('with Remove animations on, a new row shows at once', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final (g, _) = await seed(['Dana', 'Yossi']);
    await openGroup(tester, g);
    expect(
      MediaQuery.of(tester.element(find.byType(GroupPage))).disableAnimations,
      isTrue,
    );
    await openAdd(tester);
    await type(tester, '300');
    await pick(tester, Category.hotel);
    await tester.tap(find.text(MessageKey.save.text));
    // Zero-duration frames only: the save, the route and the stream.
    for (
      var i = 0;
      i < 10 && find.byType(ExpenseRowCard).evaluate().isEmpty;
      i++
    ) {
      await tester.pump();
    }
    await tester.pump();
    expect(find.byType(ExpenseRowCard), findsOneWidget);
    for (final t in tester.widgetList<SizeTransition>(
      find.descendant(
        of: find.byType(ExpenseList),
        matching: find.byType(SizeTransition),
      ),
    )) {
      expect(t.sizeFactor.value, 1);
    }
    expect(
      tester.getSize(find.byType(ExpenseRowCard)).height,
      greaterThanOrEqualTo(72),
    );
    expect(tester.hasRunningAnimations, isFalse);
    await unmountGrouPay(tester);
  });
}
