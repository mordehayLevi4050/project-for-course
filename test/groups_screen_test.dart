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

void main() {
  testWidgets('create and delete a group from the home screen', (tester) async {
    final store = _MemoryStore();
    final state = AppState(store);
    await state.load();
    await tester.pumpWidget(GroupayApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('GrouPay'), findsOneWidget);
    expect(find.text('עוד אין קבוצות'), findsOneWidget);

    // Create.
    await tester.tap(find.text('פתח קבוצה ראשונה'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'טיול צפון');
    await tester.pump();
    await tester.tap(find.text('צור'));
    await tester.pumpAndSettle();

    expect(find.text('טיול צפון'), findsOneWidget);
    expect(find.text('הקבוצות שלי'), findsOneWidget);
    expect(store.saved.single.name, 'טיול צפון');

    // Open the group: the header shows the group name.
    await tester.tap(find.text('טיול צפון'));
    await tester.pumpAndSettle();
    expect(find.text('GrouPay'), findsOneWidget);
    expect(find.text('טיול צפון'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    // Delete.
    await tester.longPress(find.text('טיול צפון'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מחק'));
    await tester.pumpAndSettle();

    expect(find.text('עוד אין קבוצות'), findsOneWidget);
    expect(store.saved, isEmpty);
  });
}
