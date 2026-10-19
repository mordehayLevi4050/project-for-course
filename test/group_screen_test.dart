import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/data/json_storage.dart';
import 'package:groupay/logic/money.dart';
import 'package:groupay/main.dart';
import 'package:groupay/models/categories.dart';
import 'package:groupay/models/group.dart';
import 'package:groupay/state/app_state.dart';

class _MemoryStore implements GroupStore {
  List<Group> saved = [];
  List<String>? categories;

  @override
  Future<List<Group>> load() async => saved;

  @override
  Future<List<String>?> loadCategories() async => categories;

  @override
  Future<void> save(List<Group> groups, List<String> categories) async {
    saved = groups;
    this.categories = categories;
  }
}

Future<void> _chooseCategory(WidgetTester tester, String category) async {
  final dropdown = find.byType(DropdownButtonFormField<String>);
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(category).last);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text('הוספת ההוצאה'));
  await tester.tap(find.text('הוספת ההוצאה'));
  await tester.pumpAndSettle();
}

Future<void> _addMember(WidgetTester tester, String name) async {
  await tester.enterText(find.widgetWithText(TextField, 'שם משתתף'), name);
  await tester.tap(find.byTooltip('הוסף'));
  await tester.pumpAndSettle();
}

/// [notSharedWith] are unchecked in "עם מי מתחלק?"; by default everyone shares.
Future<void> _addExpense(
  WidgetTester tester,
  String payer,
  String amount,
  String category, {
  List<String> notSharedWith = const [],
}) async {
  await tester.tap(find.text('הוצאה חדשה'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), amount);
  await tester.tap(find.widgetWithText(ChoiceChip, payer));
  for (final name in notSharedWith) {
    final chip = find.widgetWithText(FilterChip, name);
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
  }
  await _chooseCategory(tester, category);
  await tester.enterText(find.widgetWithText(TextField, 'פירוט (לא חובה)'), 'פירוט של $category');
  await tester.pump();
  await _tapSave(tester);
}

void main() {
  testWidgets('members, expenses and who-owes-whom', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final store = _MemoryStore();
    final state = AppState(store);
    await state.load();
    final group = await state.addGroup('טיול צפון');
    await tester.pumpWidget(GroupayApp(state: state));
    await tester.tap(find.text('טיול צפון'));
    await tester.pumpAndSettle();

    // No members yet: the card asks to add them and there is no FAB.
    expect(find.text('הוצאה חדשה'), findsNothing);
    await tester.tap(find.text('הוספת משתתפים'));
    await tester.pumpAndSettle();
    await _addMember(tester, 'דני');
    await _addMember(tester, 'רוני');
    await _addMember(tester, 'מאיה');
    await _addMember(tester, 'דני');
    expect(find.text('השם "דני" כבר קיים בקבוצה'), findsOneWidget);
    expect(state.groupById(group.id)!.members.length, 3);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    // Validation: empty form is not saved.
    await tester.tap(find.text('הוצאה חדשה'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('הוספת ההוצאה'));
    await tester.pump();
    expect(find.text('הזינו סכום גדול מ-0'), findsOneWidget);
    expect(find.text('בחרו מי שילם'), findsOneWidget);
    expect(find.text('בחרו קטגוריה'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await _addExpense(tester, 'דני', '300', 'דלק');
    await _addExpense(tester, 'רוני', '60', 'מסעדה');

    // Summary at the top: total 360, 120 each, two transfers to Dani.
    final g = state.groupById(group.id)!;
    expect(g.totalAgorot, 36000);
    expect(find.text('מי חייב למי'), findsOneWidget);
    expect(find.textContaining('360'), findsWidgets);
    expect(find.textContaining('120'), findsWidgets);
    expect(find.textContaining('60'), findsWidgets);
    expect(find.text('הוצאות (2)'), findsOneWidget);

    // Tap an expense to see its details, then delete it.
    await tester.tap(find.text('מסעדה'));
    await tester.pumpAndSettle();
    expect(find.text('פירוט של מסעדה'), findsOneWidget);
    await tester.tap(find.text('מחיקת ההוצאה'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחק'));
    await tester.pumpAndSettle();
    expect(find.text('הוצאות (1)'), findsOneWidget);
    expect(store.saved.single.expenses.single.title, 'דלק');

    // A member who paid cannot be deleted.
    expect(await state.deleteMember(group.id, g.members.first.id), isFalse);
  });

  testWidgets('an expense shared with specific members only', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final state = AppState(_MemoryStore());
    await state.load();
    final group = await state.addGroup('בודפשט');
    await tester.pumpWidget(GroupayApp(state: state));
    await tester.tap(find.text('בודפשט'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('הוספת משתתפים'));
    await tester.pumpAndSettle();
    for (final name in ['מוטי', 'דני', 'יוסי', 'שמוליק']) {
      await _addMember(tester, name);
    }
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    // Motty and Dany each paid 200 for everyone; Yosi paid 100 for himself and Shmulik.
    await _addExpense(tester, 'מוטי', '200', 'לינה');
    await _addExpense(tester, 'דני', '200', 'מסעדה');
    await _addExpense(tester, 'יוסי', '100', 'תחבורה', notSharedWith: ['מוטי', 'דני']);

    final g = state.groupById(group.id)!;
    String idOf(String name) => g.members.firstWhere((m) => m.name == name).id;
    final taxi = g.expenses.firstWhere((e) => e.title == 'תחבורה');
    expect(taxi.participantIds, [idOf('יוסי'), idOf('שמוליק')]);
    expect(g.expenses.where((e) => e.title != 'תחבורה').map((e) => e.participantIds),
        everyElement(isEmpty));

    // Shares: Motty and Dany 100, Yosi and Shmulik 100 + 50.
    // Balances: Motty +100, Dany +100, Yosi -50, Shmulik -150.
    expect(find.text('מקבל/ת ${formatShekels(10000)}'), findsNWidgets(2));
    expect(find.text('חייב/ת ${formatShekels(5000)}'), findsOneWidget);
    expect(find.text('חייב/ת ${formatShekels(15000)}'), findsOneWidget);
  });

  testWidgets('expense category from the list; "אחר" requires details', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final store = _MemoryStore();
    final state = AppState(store);
    await state.load();
    // First run writes the default categories to the store.
    expect(store.categories, defaultCategories);
    final group = await state.addGroup('טיול');
    await state.addMember(group.id, 'דני');
    await tester.pumpWidget(GroupayApp(state: state));
    await tester.tap(find.text('טיול'));
    await tester.pumpAndSettle();

    // Choose "דלק" from the list: saved with that category.
    await _addExpense(tester, 'דני', '100', 'דלק');
    expect(store.saved.single.expenses.single.title, 'דלק');

    // Choose "אחר" without details: not saved, error shown.
    await tester.tap(find.text('הוצאה חדשה'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '20');
    await _chooseCategory(tester, otherCategory);
    expect(find.widgetWithText(TextField, 'פירוט'), findsOneWidget);
    await _tapSave(tester);
    expect(find.text('נדרש פירוט'), findsOneWidget);
    expect(state.groupById(group.id)!.expenses.length, 1);

    // With details it is saved.
    await tester.enterText(find.widgetWithText(TextField, 'פירוט'), 'קולה בתחנת דלק');
    await tester.pump();
    await _tapSave(tester);
    final other = store.saved.single.expenses.first;
    expect(other.title, otherCategory);
    expect(other.details, 'קולה בתחנת דלק');
    expect(other.amountAgorot, 2000);
  });
}
