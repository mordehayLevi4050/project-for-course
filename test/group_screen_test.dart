import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/data/json_storage.dart';
import 'package:groupay/main.dart';
import 'package:groupay/models/group.dart';
import 'package:groupay/state/app_state.dart';

class _MemoryStore implements GroupStore {
  List<Group> saved = [];

  @override
  Future<List<Group>> load() async => saved;

  @override
  Future<void> save(List<Group> groups) async => saved = groups;
}

Future<void> _addMember(WidgetTester tester, String name) async {
  await tester.enterText(find.widgetWithText(TextField, 'שם משתתף'), name);
  await tester.tap(find.byTooltip('הוסף'));
  await tester.pumpAndSettle();
}

Future<void> _addExpense(WidgetTester tester, String payer, String amount, String title) async {
  await tester.tap(find.text('הוצאה חדשה'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), amount);
  await tester.tap(find.widgetWithText(ChoiceChip, payer));
  await tester.enterText(find.widgetWithText(TextField, 'על מה?'), title);
  await tester.enterText(find.widgetWithText(TextField, 'פירוט (לא חובה)'), 'פירוט של $title');
  await tester.pump();
  await tester.tap(find.text('הוספת ההוצאה'));
  await tester.pumpAndSettle();
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
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await _addExpense(tester, 'דני', '300', 'דלק');
    await _addExpense(tester, 'רוני', '60', 'קפה');

    // Summary at the top: total 360, 120 each, two transfers to Dani.
    final g = state.groupById(group.id)!;
    expect(g.totalAgorot, 36000);
    expect(find.text('מי חייב למי'), findsOneWidget);
    expect(find.textContaining('360'), findsWidgets);
    expect(find.textContaining('120'), findsWidgets);
    expect(find.textContaining('60'), findsWidgets);
    expect(find.text('הוצאות (2)'), findsOneWidget);

    // Tap an expense to see its details, then delete it.
    await tester.tap(find.text('קפה'));
    await tester.pumpAndSettle();
    expect(find.text('פירוט של קפה'), findsOneWidget);
    await tester.tap(find.text('מחיקת ההוצאה'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחק'));
    await tester.pumpAndSettle();
    expect(find.text('הוצאות (1)'), findsOneWidget);
    expect(store.saved.single.expenses.single.title, 'דלק');

    // A member who paid cannot be deleted.
    expect(await state.deleteMember(group.id, g.members.first.id), isFalse);
  });
}
