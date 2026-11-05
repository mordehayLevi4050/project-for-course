import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
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

  group('the Category grid fit (measured)', () {
    /// A screen, in physical pixels, with its system insets in dp.
    const emulator = (
      size: Size(1080, 2400),
      dpr: 2.625,
      top: 50.0,
      bottom: 24.0,
    );
    const s25 = (size: Size(1080, 2340), dpr: 3.0, top: 32.0, bottom: 24.0);
    const screens = {'emulator': emulator, 's25': s25};
    // Tall enough that the grid always fits: the width, and so every
    // measured line, stays the screen's.
    Size tall(Size size) => Size(size.width, 20000);

    const shortNames = [
      'Dana', 'Yossi', 'Noa', 'Avi', 'Tal', //
      'Gil', 'Ron', 'Lior', 'Maya', 'Eli',
    ];
    // Ten letters each, the longest a Member name can be: two lines under
    // the avatar.
    const longNames = [
      'Alexandria',
      'Bernadette',
      'Christophe',
      'Evangeline',
      'Fitzgerald',
      'Gwendolynn',
      'Hildegarde',
      'Jacquelina',
      'Konstantin',
      'Maximilian',
    ];

    void useScreen(
      WidgetTester tester,
      ({Size size, double dpr, double top, double bottom}) screen, {
      Size? size,
    }) {
      tester.view.physicalSize = size ?? screen.size;
      tester.view.devicePixelRatio = screen.dpr;
      final padding = FakeViewPadding(
        top: screen.top * screen.dpr,
        bottom: screen.bottom * screen.dpr,
      );
      tester.view.padding = padding;
      tester.view.viewPadding = padding;
      addTearDown(tester.view.reset);
    }

    Future<void> openAt(WidgetTester tester, String location) async {
      await pumpGrouPay(tester, db, initialLocation: location, clock: clock);
      expect(find.byType(AddExpenseScreen), findsOneWidget);
    }

    Finder region() => find.descendant(
      of: find.byType(AddExpenseScreen),
      matching: find.byType(SingleChildScrollView),
    );

    double maxScroll(WidgetTester tester) => tester
        .state<ScrollableState>(
          find
              .descendant(of: region(), matching: find.byType(Scrollable))
              .first,
        )
        .position
        .maxScrollExtent;

    bool twoPage() =>
        find.byKey(const ValueKey('category-pages')).evaluate().isNotEmpty;

    /// The estimate the screen decides with, measured at the region.
    double estimate(
      WidgetTester tester,
      List<Member> members, {
      bool edit = false,
    }) {
      final metrics = ExpenseRegionMetrics(
        payerRows: members.length > 6 ? 2 : 1,
        metaLine: edit,
      );
      final context = tester.element(
        find.byKey(const ValueKey('amount-message')),
      );
      final meta = find.byKey(const ValueKey('edit-meta'));
      return metrics.gridRegionHeight(
        context,
        tester.getSize(region()).width - 2 * AppSpacing.marginMobile,
        buffer: amountText(tester),
        metaText: meta.evaluate().isEmpty
            ? null
            : tester.widget<Text>(meta).data,
        messageText: slot(tester),
        members: members,
        compact: members.length > 6,
      );
    }

    /// The rendered region: its Column plus the top and bottom padding.
    double rendered(WidgetTester tester, {bool edit = false}) {
      final column = find
          .descendant(of: region(), matching: find.byType(Column))
          .first;
      final padding = ExpenseRegionMetrics(
        payerRows: 1,
        metaLine: edit,
      ).regionPadding;
      return tester.getSize(column).height + 2 * padding;
    }

    double amountSize(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const ValueKey('amount-text')))
        .style!
        .fontSize!;

    setUpAll(loadHeebo);

    for (final count in [2, 6, 10]) {
      for (final (label, names) in [
        ('short', shortNames),
        ('long', longNames),
      ]) {
        for (final scale in [1.0, 1.3, 1.5]) {
          for (final MapEntry(key: screenName, value: screen)
              in screens.entries) {
            testWidgets(
              '$count $label names, scale $scale, $screenName: the estimate '
              'is the rendered height, and decides the layout',
              (tester) async {
                tester.platformDispatcher.textScaleFactorTestValue = scale;
                addTearDown(
                  tester.platformDispatcher.clearTextScaleFactorTestValue,
                );
                final (g, byName) = await seed(names.take(count).toList());
                final members = [for (final n in names.take(count)) byName[n]!];

                // On a tall screen of the same width the grid is laid out:
                // the estimate matches it.
                useScreen(tester, screen, size: tall(screen.size));
                await openAt(tester, '/group/$g/add');
                expect(twoPage(), isFalse);
                final grid = estimate(tester, members);
                expect(rendered(tester), closeTo(grid, 1));
                await unmountGrouPay(tester);

                // On the real screen the same estimate picks the layout.
                useScreen(tester, screen);
                await openAt(tester, '/group/$g/add');
                expect(estimate(tester, members), closeTo(grid, 0.001));
                final viewport = tester.getSize(region()).height;
                expect(twoPage(), grid > viewport);
                if (!twoPage()) expect(maxScroll(tester), 0);
                expect(tester.takeException(), isNull);
                await unmountGrouPay(tester);
              },
            );
          }
        }
      }
    }

    testWidgets('emulator, 10 Members: the compact 4×2 grid, no scroll; '
        'Save works with the default Payer', (tester) async {
      final (g, byName) = await seed(shortNames);
      useScreen(tester, emulator);
      await openAt(tester, '/group/$g/add');

      expect(twoPage(), isFalse);
      expect(find.byType(PageView), findsNothing);
      expect(maxScroll(tester), 0);
      expect(amountSize(tester), AppTextStyles.amountEntryCompact.fontSize);
      expect(
        AppTextStyles.amountEntry.fontSize! -
            AppTextStyles.amountEntryCompact.fontSize!,
        lessThanOrEqualTo(6),
      );
      for (final c in Category.values) {
        final rect = tester.getRect(tile(c));
        expect(rect.height, AppSizes.categoryTileHeightCompact);
        expect(rect.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
        expect(AppSizes.categoryTileHeight - rect.height, lessThanOrEqualTo(8));
        // Both rows sit inside the region, above the keypad.
        expect(rect.bottom, lessThanOrEqualTo(tester.getRect(region()).bottom));
      }
      // Labels are never truncated.
      for (final c in Category.values) {
        final text = find.descendant(
          of: tile(c),
          matching: find.text(c.label.text),
        );
        expect(
          tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
          isFalse,
        );
        expect(
          tester.getRect(text).bottom,
          lessThanOrEqualTo(tester.getRect(tile(c)).bottom),
        );
      }

      // Selecting a tile (bold label) changes nothing in the layout.
      final before = rendered(tester);
      await type(tester, '87.4');
      await pick(tester, Category.foodDrink);
      expect(rendered(tester), before);
      expect(maxScroll(tester), 0);
      await save(tester);
      final row = (await rows()).single;
      expect(row.category, 'food_drink');
      expect(row.payerId, byName['Dana']!.id);
      expect(find.byType(GroupPage), findsOneWidget);
      await unmountGrouPay(tester);
    });

    testWidgets('S25, 10 Members: the two-page row, at the full sizes', (
      tester,
    ) async {
      final (g, _) = await seed(shortNames);
      useScreen(tester, s25);
      await openAt(tester, '/group/$g/add');

      expect(twoPage(), isTrue);
      expect(amountSize(tester), AppTextStyles.amountEntry.fontSize);
      expect(
        tester.getSize(tile(Category.flight)).height,
        greaterThanOrEqualTo(AppSizes.categoryTileHeight),
      );
      await unmountGrouPay(tester);
    });

    for (final MapEntry(key: screenName, value: screen) in screens.entries) {
      testWidgets('6 Members, $screenName: unchanged sizes; the grid on '
          'the emulator, the two-page row on S25', (tester) async {
        final (g, byName) = await seed(shortNames.take(6).toList());
        final members = [for (final n in shortNames.take(6)) byName[n]!];
        useScreen(tester, screen);
        await openAt(tester, '/group/$g/add');

        final fits =
            estimate(tester, members) <= tester.getSize(region()).height;
        // The emulator has room for one payer row; S25 with its insets
        // misses by a few dp (as with the old estimate).
        expect(fits, screen == emulator);
        expect(twoPage(), screen != emulator);
        expect(twoPage(), !fits);
        if (fits) expect(maxScroll(tester), 0);
        expect(amountSize(tester), AppTextStyles.amountEntry.fontSize);
        for (final c in Category.values) {
          expect(
            tester.getSize(tile(c)).height,
            greaterThanOrEqualTo(AppSizes.categoryTileHeight),
          );
        }
        await unmountGrouPay(tester);
      });
    }

    testWidgets('Edit, 10 Members, emulator: the estimate (with the meta '
        'line) decides, and the grid never scrolls', (tester) async {
      final (g, byName) = await seed(shortNames);
      final members = [for (final n in shortNames) byName[n]!];
      final id = newId();
      await DriftExpenseRepository(
        db,
        clock,
        DriftMemberRepository(db, clock, DriftPayerUsage(db)),
      ).add(
        id: id,
        groupId: g,
        payerId: members.first.id,
        amount: Tenths(870),
        category: Category.foodDrink,
      );

      useScreen(tester, emulator, size: tall(emulator.size));
      await openAt(tester, '/group/$g/edit/$id');
      expect(find.byKey(const ValueKey('edit-meta')), findsOneWidget);
      final grid = estimate(tester, members, edit: true);
      expect(rendered(tester, edit: true), closeTo(grid, 1));
      await unmountGrouPay(tester);

      useScreen(tester, emulator);
      await openAt(tester, '/group/$g/edit/$id');
      final viewport = tester.getSize(region()).height;
      expect(grid, lessThanOrEqualTo(viewport));
      expect(twoPage(), isFalse);
      expect(maxScroll(tester), 0);
      expect(amountSize(tester), AppTextStyles.amountEntryCompact.fontSize);
      await unmountGrouPay(tester);
    });

    testWidgets('bold text, 10 long names, scale 1.3, emulator: the estimate '
        'is the rendered height, and decides the layout', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(boldText: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final (g, byName) = await seed(longNames);
      final members = [for (final n in longNames) byName[n]!];

      useScreen(tester, emulator, size: tall(emulator.size));
      await openAt(tester, '/group/$g/add');
      expect(
        MediaQuery.boldTextOf(
          tester.element(find.byKey(const ValueKey('amount-message'))),
        ),
        isTrue,
      );
      expect(twoPage(), isFalse);
      final grid = estimate(tester, members);
      expect(rendered(tester), closeTo(grid, 1));
      await unmountGrouPay(tester);

      useScreen(tester, emulator);
      await openAt(tester, '/group/$g/add');
      final viewport = tester.getSize(region()).height;
      expect(twoPage(), grid > viewport);
      if (!twoPage()) expect(maxScroll(tester), 0);
      expect(tester.takeException(), isNull);
      await unmountGrouPay(tester);
    });
  });
}
