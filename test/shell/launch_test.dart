import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/ui/group_list_screen.dart';
import 'package:groupay/features/expenses/ui/group_page.dart';
import 'package:groupay/shell/bootstrap.dart';

import '../support/app_harness.dart';
import '../support/fake_clock.dart';

void main() {
  late AppDatabase db;
  late DriftGroupRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = DriftGroupRepository(db, FakeClock());
  });
  tearDown(() => db.close());

  Future<Group> create(String name) async =>
      ((await repo.createGroup(id: newId(), name: name)) as Ok<Group>).value;

  group('initialLocationFor', () {
    test('an Active group opens its page', () {
      expect(initialLocationFor('abc'), '/group/abc');
    });

    test('no Active group opens the group list', () {
      expect(initialLocationFor(null), '/');
    });
  });

  /// Launches through `buildGrouPay`, the same bootstrap `main()` runs.
  Future<void> launch(WidgetTester tester) => launchGrouPay(tester, db);

  testWidgets('Budapest active: launch opens its page directly', (
    tester,
  ) async {
    await create('Eilat');
    final budapest = await create('Budapest');
    await repo.setActive(id: budapest.id);

    await launch(tester);
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.byType(GroupListScreen), findsNothing);
    expect(find.text('Budapest'), findsOneWidget);

    // Back (or the nav) leads to the group list, where Eilat can be opened.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(GroupListScreen), findsOneWidget);
    await tester.tap(find.text('Eilat'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupPage), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('no Active group: launch opens the group list', (tester) async {
    await create('Eilat');
    await launch(tester);
    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(find.text(MessageKey.activeBadge.text), findsNothing);
    await unmountGrouPay(tester);
  });

  testWidgets('after archiving the Active group, launch opens the list', (
    tester,
  ) async {
    final budapest = await create('Budapest');
    await repo.setActive(id: budapest.id);
    await repo.archive(id: budapest.id);
    await launch(tester);
    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(find.text(MessageKey.archiveLink.fill({'n': '1'})), findsOneWidget);
    await unmountGrouPay(tester);
  });
}
