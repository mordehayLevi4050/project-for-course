import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/isolate_name.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/money/format_shekel.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/core/ui/widgets/member_avatar.dart';
import 'package:groupay/features/expenses/data/drift_expense_repository.dart';
import 'package:groupay/features/expenses/data/drift_payer_usage.dart';
import 'package:groupay/features/expenses/domain/category.dart';
import 'package:groupay/features/expenses/domain/expense.dart';
import 'package:groupay/features/expenses/ui/add_expense_screen.dart';
import 'package:groupay/features/expenses/ui/expense_list.dart';
import 'package:groupay/features/expenses/ui/group_page.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/member.dart';
import 'package:groupay/features/groups/ui/group_settings_screen.dart';
import 'package:groupay/features/groups/ui/member_list.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_clock.dart';
import '../../../support/heebo.dart';

/// Story 1.3 part B: Edit expense (FR-13), Delete (FR-14), view-only rows in
/// an Archived group (FR-6) and the Remove-member sheet body (FR-4).
void main() {
  late AppDatabase db;
  late FakeClock clock;

  int at(int hour) =>
      DateTime(2026, 12, 14, hour).toUtc().millisecondsSinceEpoch;

  setUp(() {
    db = AppDatabase.memory();
    clock = FakeClock(at(10));
  });
  tearDown(() => db.close());

  void usePhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<(String, Map<String, Member>)> seed(List<String> names) async {
    final group = await DriftGroupRepository(
      db,
      clock,
    ).createGroup(id: newId(), name: 'Budapest') as Ok<Group>;
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

  Future<Expense> record(
    String groupId,
    Member payer,
    int tenths,
    Category category, {
    String? description,
  }) async =>
      (await DriftExpenseRepository(
                db,
                clock,
                DriftMemberRepository(db, clock, DriftPayerUsage(db)),
              ).add(
                id: newId(),
                groupId: groupId,
                payerId: payer.id,
                amount: Tenths(tenths),
                category: category,
                description: description,
              )
              as Ok<Expense>)
          .value;

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

  Finder row(String title) => find.ancestor(
    of: find.text(title),
    matching: find.byType(ExpenseRowCard),
  );

  Future<void> openEdit(WidgetTester tester, String title) async {
    await tapAndSettle(tester, row(title));
    expect(find.byType(AddExpenseScreen), findsOneWidget);
  }

  Future<void> type(WidgetTester tester, String amount) async {
    for (final ch in amount.split('')) {
      final name = ch == '.' ? 'decimalPoint' : 'digit$ch';
      await tester.tap(find.byKey(ValueKey('keypad-$name')));
      await tester.pump();
    }
  }

  Future<void> backspace(WidgetTester tester, [int times = 1]) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(find.byKey(const ValueKey('keypad-backspace')));
      await tester.pump();
    }
  }

  Finder tile(Category c) => find.byKey(ValueKey('category-${c.key}'));

  bool tileSelected(WidgetTester tester, Category c) =>
      tester
          .widget<Text>(
            find.descendant(of: tile(c), matching: find.text(c.label.text)),
          )
          .style
          ?.fontWeight ==
      FontWeight.w800;

  Future<void> save(WidgetTester tester) =>
      tapAndSettle(tester, find.text(MessageKey.save.text));

  String amountText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('amount-text'))).data!;

  String slot(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('amount-message'))).data!;

  String meta(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('edit-meta'))).data!;

  bool? payerSelected(WidgetTester tester, Member m) => tester
      .widget<MemberAvatar>(
        find.descendant(
          of: find.byKey(ValueKey('payer-${m.id}')),
          matching: find.byType(MemberAvatar),
        ),
      )
      .selected;

  Future<List<ExpenseRow>> rows() => (db.select(
    db.expenses,
  )..orderBy([(e) => OrderingTerm.asc(e.saveSeq)])).get();

  Finder sheetText(String text) =>
      find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

  String total(int tenths) => formatShekel(Tenths(tenths));

  testWidgets('₪870 → 87: prefilled, same place, total −₪783, createdAt kept', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    final food = await record(g, m['Dana']!, 8700, Category.foodDrink);
    clock.now = at(11);
    await record(g, m['Yossi']!, 1000, Category.car);
    clock.now = at(12);
    await openGroup(tester, g);
    expect(find.text(total(9700)), findsOneWidget);

    await openEdit(tester, MessageKey.categoryFoodDrink.text);
    // Every field filled; the chip on the end (left) side; never edited.
    expect(amountText(tester), '870');
    expect(payerSelected(tester, m['Dana']!), isTrue);
    expect(payerSelected(tester, m['Yossi']!), isFalse);
    expect(tileSelected(tester, Category.foodDrink), isTrue);
    expect(meta(tester), 'נרשם 10:00');
    expect(slot(tester), '');
    final chip = tester.getCenter(find.text(MessageKey.deleteChip.text));
    expect(
      chip.dx,
      lessThan(tester.getSize(find.byType(AddExpenseScreen)).width / 2),
    );
    // The meta line sits under the Amount, above the message slot.
    expect(
      tester.getRect(find.byKey(const ValueKey('edit-meta'))).top,
      greaterThan(
        tester.getRect(find.byKey(const ValueKey('amount-text'))).top,
      ),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('edit-meta'))).bottom,
      lessThanOrEqualTo(
        tester.getRect(find.byKey(const ValueKey('amount-message'))).top,
      ),
    );

    await backspace(tester);
    await save(tester);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.text(total(870)), findsOneWidget);
    expect(find.text(total(1870)), findsOneWidget);
    // Same place: the car row (saved later) stays on top.
    expect(
      tester.getRect(row(MessageKey.categoryCar.text)).top,
      lessThan(tester.getRect(row(MessageKey.categoryFoodDrink.text)).top),
    );
    // The row still shows the recorded time.
    expect(find.textContaining('10:00'), findsOneWidget);

    final saved = (await rows()).first;
    expect(saved.id, food.id);
    expect(saved.amount, 870);
    expect(saved.saveSeq, 1);
    expect(saved.createdAt, at(10));
    expect(saved.modifiedAt, at(12));

    await openEdit(tester, MessageKey.categoryFoodDrink.text);
    expect(meta(tester), 'נרשם 10:00 · נערך 12:00');
    // No change: ✕ closes at once.
    await tapAndSettle(tester, find.text(MessageKey.close.text));
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('₪87 → 0 is not saved: "סכום לא תקין"', (tester) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 870, Category.hotel);
    await openGroup(tester, g);
    await openEdit(tester, MessageKey.categoryHotel.text);
    await backspace(tester, 2);
    await type(tester, '0');
    await save(tester);
    expect(find.byType(AddExpenseScreen), findsOneWidget);
    expect(slot(tester), MessageKey.invalidAmount.text);
    expect(tileSelected(tester, Category.hotel), isTrue);
    expect(payerSelected(tester, m['Dana']!), isTrue);
    final saved = (await rows()).single;
    expect(saved.amount, 870);
    expect(saved.modifiedAt, saved.createdAt);
    await unmountGrouPay(tester);
  });

  testWidgets(
    'Dana → Yossi keeps saveSeq and time; next Add defaults to Yossi',
    (tester) async {
      final (g, m) = await seed(['Dana', 'Yossi']);
      await record(g, m['Yossi']!, 100, Category.fuel);
      await record(g, m['Dana']!, 200, Category.car);
      clock.now = at(12);
      await openGroup(tester, g);
      await openEdit(tester, MessageKey.categoryCar.text);
      await tapAndSettle(
        tester,
        find.byKey(ValueKey('payer-${m['Yossi']!.id}')),
      );
      await save(tester);

      final saved = (await rows()).last;
      expect(saved.payerId, m['Yossi']!.id);
      expect(saved.saveSeq, 2);
      expect(saved.createdAt, at(10));

      await tapAndSettle(tester, find.text(MessageKey.addExpense.text));
      expect(payerSelected(tester, m['Yossi']!), isTrue);
      await unmountGrouPay(tester);
    },
  );

  testWidgets('at text scale 1.5 a 🍝 row opens on page 2', (tester) async {
    await loadHeebo();
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 500, Category.restaurant);
    await openGroup(tester, g);
    await openEdit(tester, MessageKey.categoryRestaurant.text);

    final pages = find.byKey(const ValueKey('category-pages'));
    expect(pages, findsOneWidget);
    final width = tester.getSize(find.byType(AddExpenseScreen)).width;
    // Page 2 is in view; page 1 lies beyond the start (right) edge.
    final restaurant = tester.getRect(tile(Category.restaurant));
    expect(restaurant.left, greaterThanOrEqualTo(0));
    expect(restaurant.right, lessThanOrEqualTo(width));
    expect(tester.getRect(tile(Category.flight)).center.dx, greaterThan(width));
    expect(tileSelected(tester, Category.restaurant), isTrue);
    // Nothing above the keypad is pushed under it, meta line included.
    expect(
      tester.getRect(pages).bottom,
      lessThan(tester.getRect(find.byKey(const ValueKey('keypad-digit1'))).top),
    );
    expect(find.byKey(const ValueKey('edit-meta')), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('no change: ✕, back and Save close at once, nothing written', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 50, Category.other, description: 'Map');
    clock.now = at(12);
    await openGroup(tester, g);

    await openEdit(tester, 'Map');
    expect(find.byKey(const ValueKey('description-field')), findsOneWidget);
    await tapAndSettle(tester, find.text(MessageKey.close.text));
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);

    await openEdit(tester, 'Map');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);

    await openEdit(tester, 'Map');
    await save(tester);
    expect(find.byType(GroupPage), findsOneWidget);
    final saved = (await rows()).single;
    expect(saved.modifiedAt, saved.createdAt);

    await openEdit(tester, 'Map');
    expect(meta(tester), 'נרשם 10:00');
    await unmountGrouPay(tester);
  });

  testWidgets('a changed field: ✕ and back open the Exit sheet', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 870, Category.hotel);
    await openGroup(tester, g);
    await openEdit(tester, MessageKey.categoryHotel.text);

    await tapAndSettle(tester, tile(Category.car));
    await tapAndSettle(tester, find.text(MessageKey.close.text));
    expect(find.text(MessageKey.exitTitle.text), findsOneWidget);
    await tapAndSettle(tester, sheetText(MessageKey.keepEditing.text));
    expect(tileSelected(tester, Category.car), isTrue);
    expect(amountText(tester), '87');

    // Back to the saved Category, but the Amount now differs.
    await tapAndSettle(tester, tile(Category.hotel));
    await backspace(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(MessageKey.exitTitle.text), findsOneWidget);
    await tapAndSettle(tester, sheetText(MessageKey.exitConfirm.text));
    expect(find.byType(GroupPage), findsOneWidget);
    expect((await rows()).single.amount, 870);
    await unmountGrouPay(tester);
  });

  testWidgets('long-press → Delete sheet → "מחיקה": gone, snackbar, no undo', (
    tester,
  ) async {
    final (g, m) = await seed(['מוטי', 'Dana']);
    await record(g, m['מוטי']!, 874, Category.foodDrink);
    await record(g, m['Dana']!, 3000, Category.hotel);
    await openGroup(tester, g);
    expect(find.text(total(3874)), findsOneWidget);

    await tester.longPress(row(MessageKey.categoryFoodDrink.text));
    await tester.pumpAndSettle();
    expect(sheetText(MessageKey.deleteTitle.text), findsOneWidget);
    expect(
      sheetText(
        '🛒 ${MessageKey.categoryFoodDrink.text} · ${isolateName('מוטי')} · '
        '${total(874)}',
      ),
      findsOneWidget,
    );
    expect(sheetText(MessageKey.deleteBody.text), findsOneWidget);
    expect(sheetText(MessageKey.cancel.text), findsOneWidget);

    await tapAndSettle(tester, sheetText(MessageKey.deleteConfirm.text));
    expect(find.byType(BottomSheet), findsNothing);
    expect(row(MessageKey.categoryFoodDrink.text), findsNothing);
    expect(find.text(total(3000)), findsNWidgets(2));
    expect(find.text(MessageKey.expenseDeleted.text), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
    // The snackbar floats above the bottom bar.
    expect(
      tester
          .getRect(
            find
                .descendant(
                  of: find.byType(SnackBar),
                  matching: find.byType(Material),
                )
                .first,
          )
          .bottom,
      lessThanOrEqualTo(
        tester
            .getRect(
              find.widgetWithText(FilledButton, MessageKey.addExpense.text),
            )
            .top,
      ),
    );
    expect(await rows(), hasLength(1));
    await unmountGrouPay(tester);
  });

  testWidgets('"ביטול", the scrim or back leave the Expense unchanged', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 870, Category.hotel);
    await openGroup(tester, g);
    Future<void> longPress() async {
      await tester.longPress(row(MessageKey.categoryHotel.text));
      await tester.pumpAndSettle();
      expect(sheetText(MessageKey.deleteTitle.text), findsOneWidget);
    }

    await longPress();
    await tapAndSettle(tester, sheetText(MessageKey.cancel.text));
    await longPress();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await longPress();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(row(MessageKey.categoryHotel.text), findsOneWidget);
    expect(find.text(MessageKey.expenseDeleted.text), findsNothing);
    expect(await rows(), hasLength(1));
    await unmountGrouPay(tester);
  });

  testWidgets('"🗑 מחיקה" in Edit deletes and returns to the Group page', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 870, Category.hotel);
    await record(g, m['Yossi']!, 100, Category.car);
    await openGroup(tester, g);
    await openEdit(tester, MessageKey.categoryHotel.text);

    await tapAndSettle(tester, find.text(MessageKey.deleteChip.text));
    expect(
      sheetText(
        '🏨 ${MessageKey.categoryHotel.text} · ${isolateName('Dana')} · '
        '${total(870)}',
      ),
      findsOneWidget,
    );
    await tapAndSettle(tester, sheetText(MessageKey.cancel.text));
    expect(find.byType(AddExpenseScreen), findsOneWidget);

    await tapAndSettle(tester, find.text(MessageKey.deleteChip.text));
    await tapAndSettle(tester, sheetText(MessageKey.deleteConfirm.text));
    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(row(MessageKey.categoryHotel.text), findsNothing);
    expect(find.text(MessageKey.expenseDeleted.text), findsOneWidget);
    expect((await rows()).single.category, 'car');
    await unmountGrouPay(tester);
  });

  testWidgets('Other: changing only the Description is saved trimmed', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 50, Category.other, description: 'Map');
    clock.now = at(12);
    await openGroup(tester, g);
    await openEdit(tester, 'Map');

    await tester.enterText(
      find.byKey(const ValueKey('description-field')),
      ' Atlas ',
    );
    await tester.pump();
    await tapAndSettle(tester, find.text(MessageKey.close.text));
    expect(find.text(MessageKey.exitTitle.text), findsOneWidget);
    await tapAndSettle(tester, sheetText(MessageKey.keepEditing.text));

    await save(tester);
    expect(find.byType(GroupPage), findsOneWidget);
    final saved = (await rows()).single;
    expect(saved.description, 'Atlas');
    expect(saved.modifiedAt, at(12));
    expect(saved.createdAt, at(10));
    expect(row('Atlas'), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets(
    'the Delete sheet line of an Other row isolates the Description',
    (tester) async {
      final (g, m) = await seed(['Dana', 'Yossi']);
      await record(g, m['Dana']!, 874, Category.other, description: 'Map');
      await openGroup(tester, g);
      await tester.longPress(row('Map'));
      await tester.pumpAndSettle();
      expect(
        sheetText(
          '${Category.other.emoji} ${isolateName('Map')} · '
          '${isolateName('Dana')} · ${total(874)}',
        ),
        findsOneWidget,
      );
      await tapAndSettle(tester, sheetText(MessageKey.cancel.text));
      await unmountGrouPay(tester);
    },
  );

  testWidgets('Edit of a missing Expense returns to the Group page', (
    tester,
  ) async {
    final (g, _) = await seed(['Dana', 'Yossi']);
    usePhone(tester);
    await pumpGrouPay(
      tester,
      db,
      initialLocation: '/group/$g/edit/${newId()}',
      clock: clock,
    );
    await tester.pumpAndSettle();
    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.text(MessageKey.addExpense.text), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('a swipe on a row does nothing', (tester) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 870, Category.hotel);
    await openGroup(tester, g);
    for (final dx in [-300.0, 300.0]) {
      await tester.drag(row(MessageKey.categoryHotel.text), Offset(dx, 0));
      await tester.pumpAndSettle();
    }
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(row(MessageKey.categoryHotel.text), findsOneWidget);
    expect(await rows(), hasLength(1));
    await unmountGrouPay(tester);
  });

  testWidgets('Archived: rows are inert and the edit route redirects', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    final e = await record(g, m['Dana']!, 870, Category.hotel);
    await DriftGroupRepository(db, clock).archive(id: g);
    usePhone(tester);

    await pumpGrouPay(
      tester,
      db,
      initialLocation: '/group/$g/edit/${e.id}',
      clock: clock,
    );
    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.text(MessageKey.archiveNote.text), findsOneWidget);

    await tapAndSettle(tester, row(MessageKey.categoryHotel.text));
    expect(find.byType(AddExpenseScreen), findsNothing);
    await tester.longPress(row(MessageKey.categoryHotel.text));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(await rows(), hasLength(1));
    await unmountGrouPay(tester);
  });

  testWidgets('renaming Dana to "Danna" shows on all of her rows', (
    tester,
  ) async {
    final (g, m) = await seed(['Dana', 'Yossi']);
    await record(g, m['Dana']!, 100, Category.car);
    await record(g, m['Dana']!, 200, Category.fuel);
    await record(g, m['Yossi']!, 300, Category.hotel);
    await openGroup(tester, g);
    expect(find.textContaining('Dana'), findsNWidgets(2));

    await DriftMemberRepository(
      db,
      clock,
      DriftPayerUsage(db),
    ).renameMember(id: m['Dana']!.id, name: 'Danna');
    await tester.pumpAndSettle();
    expect(find.textContaining('Danna'), findsNWidgets(2));
    expect(find.textContaining(isolateName('Dana')), findsNothing);
    await unmountGrouPay(tester);
  });

  group('Remove-member sheet body', () {
    Future<void> openRemove(WidgetTester tester, String g, String name) async {
      await openGroup(tester, g);
      await tapAndSettle(tester, find.text(MessageKey.groupSettingsChip.text));
      expect(find.byType(GroupSettingsScreen), findsOneWidget);
      await tapAndSettle(
        tester,
        find.descendant(
          of: find.widgetWithText(MemberListRow, name),
          matching: find.text(MessageKey.removeGlyph.text),
        ),
      );
      expect(
        sheetText(
          MessageKey.removeMemberTitle.fill({'name': isolateName(name)}),
        ),
        findsOneWidget,
      );
    }

    testWidgets('Expenses, 4 Members, ✕ Noa: "…בין 3 המשתתפים הנותרים."', (
      tester,
    ) async {
      final (g, m) = await seed(['Dana', 'Yossi', 'Motty', 'Noa']);
      await record(g, m['Dana']!, 100, Category.car);
      await openRemove(tester, g, 'Noa');
      expect(
        sheetText('ההוצאות יתחלקו מחדש בין 3 המשתתפים הנותרים.'),
        findsOneWidget,
      );
      await tapAndSettle(tester, sheetText(MessageKey.cancel.text));
      expect(find.widgetWithText(MemberListRow, 'Noa'), findsOneWidget);
      expect(await db.select(db.members).get(), hasLength(4));
      await unmountGrouPay(tester);
    });

    testWidgets('Expenses, 2 Members: "כל ההוצאות יחולו על המשתתף הנותר."', (
      tester,
    ) async {
      final (g, m) = await seed(['Dana', 'Yossi']);
      await record(g, m['Dana']!, 100, Category.car);
      await openRemove(tester, g, 'Yossi');
      expect(sheetText('כל ההוצאות יחולו על המשתתף הנותר.'), findsOneWidget);
      await unmountGrouPay(tester);
    });

    testWidgets('no Expenses: the title only', (tester) async {
      final (g, _) = await seed(['Dana', 'Yossi', 'Noa']);
      await openRemove(tester, g, 'Noa');
      expect(sheetText(MessageKey.removeMemberBodyOne.text), findsNothing);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('ההוצאות'),
        ),
        findsNothing,
      );
      await unmountGrouPay(tester);
    });
  });
}
