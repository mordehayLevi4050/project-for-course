import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/money/format_shekel.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/features/groups/app/repository_providers.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/group_repository.dart';
import 'package:groupay/features/groups/ui/create_group_screen.dart';
import 'package:groupay/features/groups/ui/group_list_screen.dart';
import 'package:groupay/features/groups/ui/group_page.dart';
import 'package:groupay/shell/app.dart';
import 'package:groupay/shell/router.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_clock.dart';

/// A [GroupRepository] whose createGroup completes only when the test says so.
final class _PendingGroupRepository implements GroupRepository {
  final pending = Completer<Result<Group>>();
  int calls = 0;

  @override
  Future<Result<Group>> createGroup({
    required String id,
    required String name,
  }) {
    calls++;
    return pending.future;
  }

  @override
  Stream<List<GroupListItem>> watchGroups() => Stream.value(const []);

  @override
  Stream<Group?> watchGroup(String id) => Stream.value(null);
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) => pumpGrouPay(tester, db);

  Future<void> unmount(WidgetTester tester) => unmountGrouPay(tester);

  Finder field() => find.byType(TextField);

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(field()).controller!.text;

  Future<void> openCreate(WidgetTester tester) async {
    await pumpApp(tester);
    await tester.tap(find.text(MessageKey.newGroup.text));
    await tester.pumpAndSettle();
    expect(find.byType(CreateGroupScreen), findsOneWidget);
  }

  Future<void> createGroup(WidgetTester tester, String name) async {
    await openCreate(tester);
    await tester.enterText(field(), name);
    await tester.tap(find.text(MessageKey.createGroup.text));
    await tester.pumpAndSettle();
  }

  Future<void> tapAdd(WidgetTester tester) async {
    final add = find.byKey(const ValueKey('name-field-add'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    await tester.tap(add);
    await tester.pumpAndSettle();
  }

  testWidgets('stage 1 → stage 2 → Group page → back to the list', (
    tester,
  ) async {
    await createGroup(tester, 'Trip to Eilat');

    // Stage 2: the group name is the top-bar title; the Members section.
    expect(find.text('Trip to Eilat'), findsOneWidget);
    expect(find.text(MessageKey.newGroupTitle.text), findsNothing);
    expect(find.text(MessageKey.membersSection.text), findsOneWidget);
    expect(find.text(MessageKey.done.text), findsOneWidget);
    expect(await db.select(db.groups).get(), hasLength(1));

    // "+" adds, clears the field and keeps the focus.
    await tester.enterText(field(), 'Dana');
    await tapAdd(tester);
    expect(find.text('Dana'), findsOneWidget);
    expect(fieldText(tester), isEmpty);
    expect(tester.widget<TextField>(field()).focusNode!.hasFocus, isTrue);

    // The keyboard action adds too.
    await tester.enterText(field(), 'Yossi');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Yossi'), findsOneWidget);
    expect(fieldText(tester), isEmpty);
    expect(await db.select(db.members).get(), hasLength(2));

    // The primary button sits in the lower half, on the start (right) side.
    final screen = tester.getSize(find.byType(CreateGroupScreen));
    final done = tester.getCenter(find.text(MessageKey.done.text));
    expect(done.dy, greaterThan(screen.height / 2));
    expect(done.dx, greaterThan(screen.width / 2));

    await tester.tap(find.text(MessageKey.done.text));
    await tester.pumpAndSettle();

    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.text(MessageKey.groupListNav.text), findsOneWidget);
    expect(find.text('Trip to Eilat'), findsOneWidget);
    expect(find.text(MessageKey.groupSettingsChip.text), findsOneWidget);
    expect(find.text(formatShekel(Tenths.zero)), findsOneWidget);
    expect(find.text('2 משתתפים'), findsOneWidget);

    // Back from the Group page returns to the group list, with the card.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(find.text('Trip to Eilat'), findsOneWidget);
    expect(find.text('2 משתתפים'), findsOneWidget);
    expect(find.text(MessageKey.emptyGroupList.text), findsNothing);

    await unmount(tester);
  });

  testWidgets('system back on stage 2 opens the Group page', (tester) async {
    await createGroup(tester, 'Eilat');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(GroupPage), findsOneWidget);
    expect(
      find.text(MessageKey.memberCountMany.fill({'n': '0'})),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(GroupListScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the nav "☰ הקבוצות שלי" returns to the list', (tester) async {
    await createGroup(tester, 'Eilat');
    await tester.tap(find.text(MessageKey.done.text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MessageKey.groupListNav.text));
    await tester.pumpAndSettle();
    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(
      find.text(MessageKey.memberCountMany.fill({'n': '0'})),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('a card opens its Group page; one Member reads "משתתף אחד"', (
    tester,
  ) async {
    await createGroup(tester, 'Eilat');
    await tester.enterText(field(), 'Dana');
    await tapAdd(tester);
    await tester.tap(find.text(MessageKey.done.text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MessageKey.groupListNav.text));
    await tester.pumpAndSettle();

    expect(find.text(MessageKey.memberCountOne.text), findsOneWidget);
    await tester.tap(find.text('Eilat'));
    await tester.pumpAndSettle();
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.text(MessageKey.memberCountOne.text), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('stage 1 ✕ leaves without creating anything', (tester) async {
    await openCreate(tester);
    await tester.enterText(field(), 'Eilat');
    await tester.tap(find.text(MessageKey.close.text));
    await tester.pumpAndSettle();
    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(find.text(MessageKey.emptyGroupList.text), findsOneWidget);
    expect(await db.select(db.groups).get(), isEmpty);
    await unmount(tester);
  });

  testWidgets('a blank name shows "נדרש שם" inline; typing clears it', (
    tester,
  ) async {
    await openCreate(tester);
    await tester.enterText(field(), '   ');
    await tester.tap(find.text(MessageKey.createGroup.text));
    await tester.pumpAndSettle();
    expect(find.text(MessageKey.nameRequired.text), findsOneWidget);
    expect(find.byType(CreateGroupScreen), findsOneWidget);
    expect(await db.select(db.groups).get(), isEmpty);

    await tester.enterText(field(), '   E');
    await tester.pump();
    expect(find.text(MessageKey.nameRequired.text), findsNothing);
    await unmount(tester);
  });

  testWidgets('a taken group name shows "כבר קיימת קבוצה בשם הזה"', (
    tester,
  ) async {
    await createGroup(tester, 'Budapest');
    await tester.tap(find.text(MessageKey.done.text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MessageKey.groupListNav.text));
    await tester.pumpAndSettle();

    await tester.tap(find.text(MessageKey.newGroup.text));
    await tester.pumpAndSettle();
    await tester.enterText(field(), ' budapest ');
    await tester.tap(find.text(MessageKey.createGroup.text));
    await tester.pumpAndSettle();
    expect(find.text(MessageKey.groupNameTaken.text), findsOneWidget);
    expect(await db.select(db.groups).get(), hasLength(1));
    await unmount(tester);
  });

  testWidgets('the group-name field blocks the 21st character', (tester) async {
    await openCreate(tester);
    await tester.enterText(field(), 'a' * 20);
    await tester.enterText(field(), '${'a' * 20}b');
    expect(fieldText(tester), 'a' * 20);
    // A longer paste into an empty field is cut to the limit.
    await tester.enterText(field(), '');
    await tester.enterText(field(), 'b' * 25);
    expect(fieldText(tester), 'b' * 20);
    await unmount(tester);
  });

  testWidgets('the member-name field blocks the 11th character', (
    tester,
  ) async {
    await createGroup(tester, 'Eilat');
    await tester.enterText(field(), 'Alexandrin');
    await tester.enterText(field(), 'Alexandrina');
    expect(fieldText(tester), 'Alexandrin');
    await tester.enterText(field(), '');
    await tester.enterText(field(), 'Bartholomew Smith');
    expect(fieldText(tester), 'Bartholome');
    await unmount(tester);
  });

  testWidgets('member errors show inline and add nothing', (tester) async {
    await createGroup(tester, 'Eilat');
    await tester.enterText(field(), 'Dana');
    await tapAdd(tester);

    await tester.enterText(field(), ' dana ');
    await tapAdd(tester);
    expect(find.text(MessageKey.memberNameTaken.text), findsOneWidget);
    // The input stays for correction.
    expect(fieldText(tester), ' dana ');

    await tester.enterText(field(), '');
    await tester.pump();
    expect(find.text(MessageKey.memberNameTaken.text), findsNothing);
    await tapAdd(tester);
    expect(find.text(MessageKey.nameRequired.text), findsOneWidget);

    for (var i = 2; i <= 10; i++) {
      await tester.enterText(field(), 'M$i');
      await tapAdd(tester);
    }
    await tester.enterText(field(), 'Gil');
    await tapAdd(tester);
    expect(find.text(MessageKey.membersLimit.text), findsOneWidget);
    expect(await db.select(db.members).get(), hasLength(10));
    await unmount(tester);
  });

  testWidgets('avatars share a first word → both show the full name', (
    tester,
  ) async {
    await createGroup(tester, 'Eilat');
    for (final name in ['Dana Levi', 'Dana Cohen', 'Yossi']) {
      await tester.enterText(field(), name);
      await tapAdd(tester);
    }
    expect(find.text('Dana Levi'), findsOneWidget);
    expect(find.text('Dana Cohen'), findsOneWidget);
    expect(find.text('Yossi'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('"יצירת קבוצה" is disabled while the save is in flight', (
    tester,
  ) async {
    final repo = _PendingGroupRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(repo),
          memberRepositoryProvider.overrideWithValue(
            DriftMemberRepository(db, FakeClock()),
          ),
        ],
        child: GrouPayApp(router: buildRouter()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(MessageKey.newGroup.text));
    await tester.pumpAndSettle();

    final button = find.widgetWithText(
      FilledButton,
      MessageKey.createGroup.text,
    );
    await tester.enterText(field(), 'Eilat');
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);

    await tester.tap(button);
    await tester.pump();
    expect(repo.calls, 1);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    repo.pending.complete(
      const Ok(
        Group(id: 'g', name: 'Eilat', groupSeq: 1, createdAt: 1, modifiedAt: 1),
      ),
    );
    await tester.pumpAndSettle();
    // Stage 2 replaced stage 1, and the save ran exactly once.
    expect(button, findsNothing);
    expect(find.text(MessageKey.membersSection.text), findsOneWidget);
    expect(repo.calls, 1);
    await unmount(tester);
  });
}
