import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/isolate_name.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/member.dart';
import 'package:groupay/features/groups/ui/create_group_screen.dart';
import 'package:groupay/features/groups/ui/group_list_screen.dart';
import 'package:groupay/features/groups/ui/group_page.dart';
import 'package:groupay/features/groups/ui/group_settings_screen.dart';
import 'package:groupay/features/groups/ui/member_list.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_clock.dart';
import '../../../support/fake_payer_usage.dart';

void main() {
  late AppDatabase db;
  late FakePayerUsage payerUsage;

  setUp(() {
    db = AppDatabase.memory();
    payerUsage = FakePayerUsage();
  });
  tearDown(() => db.close());

  /// Seeds a Group with [members] and returns its id and Members by name.
  Future<(String, Map<String, Member>)> seed(
    String name,
    List<String> members,
  ) async {
    final clock = FakeClock();
    final group = ((await DriftGroupRepository(
      db,
      clock,
    ).createGroup(id: newId(), name: name)) as Ok<Group>).value;
    final repo = DriftMemberRepository(db, clock, payerUsage);
    final byName = <String, Member>{};
    for (final m in members) {
      final r = await repo.addMember(id: newId(), groupId: group.id, name: m);
      byName[m] = (r as Ok<Member>).value;
    }
    return (group.id, byName);
  }

  Future<void> openSettings(WidgetTester tester, String groupId) async {
    await pumpGrouPay(
      tester,
      db,
      initialLocation: '/group/$groupId',
      payerUsage: payerUsage,
    );
    await tester.tap(find.text(MessageKey.groupSettingsChip.text));
    await tester.pumpAndSettle();
    expect(find.byType(GroupSettingsScreen), findsOneWidget);
  }

  Finder sheet() => find.byType(BottomSheet);

  Finder sheetField() =>
      find.descendant(of: sheet(), matching: find.byType(TextField));

  Finder inSheet(String text) =>
      find.descendant(of: sheet(), matching: find.text(text));

  Finder rowGlyph(String name, MessageKey glyph) => find.descendant(
    of: find.widgetWithText(MemberListRow, name),
    matching: find.text(glyph.text),
  );

  String groupValue(String name) =>
      MessageKey.rowValue.fill({'value': isolateName(name)});

  String removeTitle(String name) =>
      MessageKey.removeMemberTitle.fill({'name': isolateName(name)});

  Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<List<String>> memberNames() async => [
    for (final m in await db.select(db.members).get()) m.name,
  ];

  testWidgets('chip → settings → rename Group and Member → remove → back', (
    tester,
  ) async {
    final (groupId, _) = await seed('Trip to Eilat', ['Dana', 'Yossi']);
    await openSettings(tester, groupId);

    // The top bar, the group-name row and the Members section.
    expect(find.text(MessageKey.groupSettingsTitle.text), findsOneWidget);
    expect(find.text(MessageKey.back.text), findsOneWidget);
    expect(find.text(MessageKey.groupNameLabel.text), findsOneWidget);
    expect(find.text(groupValue('Trip to Eilat')), findsOneWidget);
    expect(find.text(MessageKey.membersCount.fill({'n': '2'})), findsOneWidget);
    expect(find.text(MessageKey.addMember.text), findsOneWidget);

    // Rename the Group.
    await tapAndSettle(tester, find.text(MessageKey.groupNameLabel.text));
    expect(inSheet(MessageKey.renameTitle.text), findsOneWidget);
    expect(
      tester.widget<TextField>(sheetField()).controller!.text,
      'Trip to Eilat',
    );
    await tester.enterText(sheetField(), 'Eilat 2026');
    await tapAndSettle(tester, inSheet(MessageKey.save.text));
    expect(sheet(), findsNothing);
    expect(find.text(groupValue('Eilat 2026')), findsOneWidget);

    // Rename Dana.
    await tapAndSettle(tester, rowGlyph('Dana', MessageKey.renameGlyph));
    expect(tester.widget<TextField>(sheetField()).controller!.text, 'Dana');
    await tester.enterText(sheetField(), 'Danna');
    await tapAndSettle(tester, inSheet(MessageKey.save.text));
    expect(sheet(), findsNothing);
    expect(find.text('Danna'), findsOneWidget);
    expect(find.text('Dana'), findsNothing);

    // ✕ on Yossi, then "ביטול": Yossi stays.
    await tapAndSettle(tester, rowGlyph('Yossi', MessageKey.removeGlyph));
    expect(inSheet(removeTitle('Yossi')), findsOneWidget);
    expect(inSheet(MessageKey.removeMemberConfirm.text), findsOneWidget);
    await tapAndSettle(tester, inSheet(MessageKey.cancel.text));
    expect(sheet(), findsNothing);
    expect(find.text('Yossi'), findsOneWidget);
    expect(await memberNames(), hasLength(2));

    // ✕ on Yossi, then "הסרה": removed.
    await tapAndSettle(tester, rowGlyph('Yossi', MessageKey.removeGlyph));
    await tapAndSettle(tester, inSheet(MessageKey.removeMemberConfirm.text));
    expect(sheet(), findsNothing);
    expect(find.text('Yossi'), findsNothing);
    expect(await memberNames(), ['Danna']);
    expect(find.text(MessageKey.membersCount.fill({'n': '1'})), findsOneWidget);

    // "→" returns to the Group page with the new name and count.
    await tapAndSettle(tester, find.text(MessageKey.back.text));
    expect(find.byType(GroupPage), findsOneWidget);
    expect(find.text('Eilat 2026'), findsOneWidget);
    expect(find.text(MessageKey.memberCountOne.text), findsOneWidget);

    // The group list card matches.
    await tapAndSettle(tester, find.text(MessageKey.groupListNav.text));
    expect(find.byType(GroupListScreen), findsOneWidget);
    expect(find.text('Eilat 2026'), findsOneWidget);
    expect(find.text(MessageKey.memberCountOne.text), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('system back from settings returns to the Group page', (
    tester,
  ) async {
    final (groupId, _) = await seed('Eilat', ['Dana']);
    await openSettings(tester, groupId);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(GroupPage), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('Group rename errors stay in the sheet; name unchanged', (
    tester,
  ) async {
    await seed('Budapest', []);
    final (groupId, _) = await seed('Eilat', []);
    await openSettings(tester, groupId);

    await tapAndSettle(tester, find.text(MessageKey.groupNameLabel.text));
    await tester.enterText(sheetField(), '  ');
    await tapAndSettle(tester, inSheet(MessageKey.save.text));
    expect(inSheet(MessageKey.nameRequired.text), findsOneWidget);
    expect(sheet(), findsOneWidget);

    await tester.enterText(sheetField(), 'Budapest');
    await tapAndSettle(tester, inSheet(MessageKey.save.text));
    expect(inSheet(MessageKey.groupNameTaken.text), findsOneWidget);
    expect(sheet(), findsOneWidget);

    // An unchanged name saves without error.
    await tester.enterText(sheetField(), 'Eilat');
    await tapAndSettle(tester, inSheet(MessageKey.save.text));
    expect(sheet(), findsNothing);
    expect(find.text(groupValue('Eilat')), findsOneWidget);
    final names = [for (final g in await db.select(db.groups).get()) g.name];
    expect(names, unorderedEquals(['Budapest', 'Eilat']));
    await unmountGrouPay(tester);
  });

  testWidgets('Member rename errors stay in the sheet; case-only saves', (
    tester,
  ) async {
    final (groupId, _) = await seed('Eilat', ['dana', 'Yossi']);
    await openSettings(tester, groupId);

    await tapAndSettle(tester, rowGlyph('dana', MessageKey.renameGlyph));
    await tester.enterText(sheetField(), '');
    await tapAndSettle(tester, inSheet(MessageKey.save.text));
    expect(inSheet(MessageKey.nameRequired.text), findsOneWidget);

    await tester.enterText(sheetField(), 'Yossi');
    await tapAndSettle(tester, inSheet(MessageKey.save.text));
    expect(inSheet(MessageKey.memberNameTaken.text), findsOneWidget);
    expect(await memberNames(), ['dana', 'Yossi']);

    await tester.enterText(sheetField(), 'Dana');
    await tapAndSettle(tester, inSheet(MessageKey.save.text));
    expect(sheet(), findsNothing);
    expect(await memberNames(), ['Dana', 'Yossi']);
    await unmountGrouPay(tester);
  });

  testWidgets('dismissing the Rename sheet writes nothing', (tester) async {
    final (groupId, _) = await seed('Eilat', ['Dana']);
    await openSettings(tester, groupId);

    Future<void> openAndType() async {
      await tapAndSettle(tester, rowGlyph('Dana', MessageKey.renameGlyph));
      await tester.enterText(sheetField(), 'Other');
    }

    await openAndType();
    await tapAndSettle(tester, inSheet(MessageKey.cancel.text));
    expect(sheet(), findsNothing);

    await openAndType();
    await tester.tapAt(const Offset(10, 10)); // the scrim
    await tester.pumpAndSettle();
    expect(sheet(), findsNothing);

    await openAndType();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(sheet(), findsNothing);
    expect(find.byType(GroupSettingsScreen), findsOneWidget);

    expect(await memberNames(), ['Dana']);
    expect(find.text('Dana'), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('dismissing the Remove sheet by scrim or back keeps the Member', (
    tester,
  ) async {
    final (groupId, _) = await seed('Eilat', ['Dana']);
    await openSettings(tester, groupId);

    await tapAndSettle(tester, rowGlyph('Dana', MessageKey.removeGlyph));
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(sheet(), findsNothing);

    await tapAndSettle(tester, rowGlyph('Dana', MessageKey.removeGlyph));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(sheet(), findsNothing);

    expect(await memberNames(), ['Dana']);
    expect(payerUsage.calls, isEmpty);
    await unmountGrouPay(tester);
  });

  testWidgets('removing a Payer is refused inline under that row', (
    tester,
  ) async {
    final (groupId, members) = await seed('Eilat', ['Dana', 'Yossi', 'Noa']);
    payerUsage.payers.addAll({members['Yossi']!.id, members['Noa']!.id});
    await openSettings(tester, groupId);

    await tapAndSettle(tester, rowGlyph('Yossi', MessageKey.removeGlyph));
    await tapAndSettle(tester, inSheet(MessageKey.removeMemberConfirm.text));
    final refusal = find.text(MessageKey.memberIsPayer.text);
    expect(refusal, findsOneWidget);
    // Under Yossi's row, above Noa's.
    expect(
      tester.getTopLeft(refusal).dy,
      greaterThan(
        tester.getBottomLeft(find.widgetWithText(MemberListRow, 'Yossi')).dy -
            1,
      ),
    );
    expect(
      tester.getBottomLeft(refusal).dy,
      lessThan(
        tester.getTopLeft(find.widgetWithText(MemberListRow, 'Noa')).dy + 1,
      ),
    );

    // A refusal on Noa replaces the one on Yossi.
    await tapAndSettle(tester, rowGlyph('Noa', MessageKey.removeGlyph));
    await tapAndSettle(tester, inSheet(MessageKey.removeMemberConfirm.text));
    expect(refusal, findsOneWidget);
    expect(
      tester.getTopLeft(refusal).dy,
      greaterThan(
        tester.getTopLeft(find.widgetWithText(MemberListRow, 'Noa')).dy,
      ),
    );

    expect(await memberNames(), ['Dana', 'Yossi', 'Noa']);
    await unmountGrouPay(tester);
  });

  testWidgets('"+ הוספת משתתף" opens the add field, which stays open', (
    tester,
  ) async {
    final (groupId, _) = await seed('Eilat', ['Dana']);
    await openSettings(tester, groupId);
    expect(find.byType(TextField), findsNothing);

    await tapAndSettle(tester, find.text(MessageKey.addMember.text));
    expect(find.text(MessageKey.addMember.text), findsNothing);
    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

    for (final name in ['Yossi', 'Noa']) {
      await tester.enterText(field, name);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    expect(find.text('Yossi'), findsOneWidget);
    expect(find.text('Noa'), findsOneWidget);
    expect(field, findsOneWidget);
    expect(find.text(MessageKey.membersCount.fill({'n': '3'})), findsOneWidget);
    await unmountGrouPay(tester);
  });

  testWidgets('rename fields block the 11th (Member) and 21st (Group) char', (
    tester,
  ) async {
    final (groupId, _) = await seed('Eilat', ['Dana']);
    await openSettings(tester, groupId);

    await tapAndSettle(tester, rowGlyph('Dana', MessageKey.renameGlyph));
    await tester.enterText(sheetField(), 'Alexandrin');
    await tester.enterText(sheetField(), 'Alexandrina');
    expect(
      tester.widget<TextField>(sheetField()).controller!.text,
      'Alexandrin',
    );
    await tapAndSettle(tester, inSheet(MessageKey.cancel.text));

    await tapAndSettle(tester, find.text(MessageKey.groupNameLabel.text));
    await tester.enterText(sheetField(), 'a' * 20);
    await tester.enterText(sheetField(), '${'a' * 20}b');
    expect(tester.widget<TextField>(sheetField()).controller!.text, 'a' * 20);
    await tapAndSettle(tester, inSheet(MessageKey.cancel.text));
    await unmountGrouPay(tester);
  });

  testWidgets(
    'Create group stage 2: ✎ renames and ✕ confirms before removing',
    (tester) async {
      await pumpGrouPay(tester, db, payerUsage: payerUsage);
      await tester.tap(find.text(MessageKey.newGroup.text));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Eilat');
      await tester.tap(find.text(MessageKey.createGroup.text));
      await tester.pumpAndSettle();
      expect(find.byType(CreateGroupScreen), findsOneWidget);

      final addField = find.descendant(
        of: find.byType(MemberAddField),
        matching: find.byType(TextField),
      );
      for (final name in ['Dana', 'Yossi']) {
        await tester.enterText(addField, name);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
      }

      await tapAndSettle(tester, rowGlyph('Dana', MessageKey.renameGlyph));
      await tester.enterText(sheetField(), 'Danna');
      await tapAndSettle(tester, inSheet(MessageKey.save.text));
      expect(find.text('Danna'), findsOneWidget);

      await tapAndSettle(tester, rowGlyph('Yossi', MessageKey.removeGlyph));
      expect(inSheet(removeTitle('Yossi')), findsOneWidget);
      await tapAndSettle(tester, inSheet(MessageKey.cancel.text));
      expect(find.text('Yossi'), findsOneWidget);

      await tapAndSettle(tester, rowGlyph('Yossi', MessageKey.removeGlyph));
      await tapAndSettle(tester, inSheet(MessageKey.removeMemberConfirm.text));
      expect(find.text('Yossi'), findsNothing);
      expect(await memberNames(), ['Danna']);
      expect(find.byType(CreateGroupScreen), findsOneWidget);
      await unmountGrouPay(tester);
    },
  );
}
