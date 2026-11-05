import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/isolate_name.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/core/ui/theme/tokens.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/ui/archive_screen.dart';
import 'package:groupay/features/groups/ui/create_group_screen.dart';
import 'package:groupay/features/groups/ui/group_card.dart';
import 'package:groupay/features/groups/ui/group_list_screen.dart';
import 'package:groupay/features/expenses/ui/group_page.dart';
import 'package:groupay/features/groups/ui/group_settings_screen.dart';
import 'package:groupay/features/groups/ui/member_list.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_clock.dart';
import '../../../support/fake_payer_usage.dart';

void main() {
  late AppDatabase db;
  late DriftGroupRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    repo = DriftGroupRepository(db, FakeClock());
  });
  tearDown(() => db.close());

  Future<Group> seed(String name, [List<String> memberNames = const []]) async {
    final group =
        ((await repo.createGroup(id: newId(), name: name)) as Ok<Group>).value;
    final members = DriftMemberRepository(db, FakeClock(), FakePayerUsage());
    for (final m in memberNames) {
      await members.addMember(id: newId(), groupId: group.id, name: m);
    }
    return group;
  }

  Finder sheet() => find.byType(BottomSheet);

  Finder inSheet(String text) =>
      find.descendant(of: sheet(), matching: find.text(text));

  String warning(String name) =>
      MessageKey.activeSheetWarning.fill({'name': isolateName(name)});

  Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<String?> activeName() async {
    final id = await repo.readActiveGroupId();
    if (id == null) return null;
    return (await repo.readGroup(id))!.name;
  }

  /// Creates [name] on stage 1 and stops with the Active-group sheet open.
  Future<void> createUpToSheet(WidgetTester tester, String name) async {
    await tapAndSettle(tester, find.text(MessageKey.newGroup.text));
    await tester.enterText(find.byType(TextField), name);
    await tapAndSettle(tester, find.text(MessageKey.createGroup.text));
    expect(find.byType(CreateGroupScreen), findsOneWidget);
    expect(inSheet(MessageKey.activeSheetTitle.text), findsOneWidget);
    expect(inSheet(MessageKey.activeSheetBody.text), findsOneWidget);
    expect(inSheet(MessageKey.activeSheetConfirm.text), findsOneWidget);
    expect(inSheet(MessageKey.activeSheetDecline.text), findsOneWidget);
    // Before any Member can be added.
    expect(find.byType(MemberAddField), findsNothing);
  }

  void expectStage2() {
    expect(sheet(), findsNothing);
    expect(find.byType(MemberAddField), findsOneWidget);
  }

  group('Create group offers the Active-group sheet (FR-7)', () {
    testWidgets('none active: no warning; "כן" makes it active', (
      tester,
    ) async {
      await pumpGrouPay(tester, db);
      await createUpToSheet(tester, 'Budapest');
      expect(find.textContaining('תפסיק להיות'), findsNothing);

      await tapAndSettle(tester, inSheet(MessageKey.activeSheetConfirm.text));
      expectStage2();
      expect(await activeName(), 'Budapest');

      // The list shows it first with the badge.
      await tapAndSettle(tester, find.text(MessageKey.done.text));
      await tapAndSettle(tester, find.text(MessageKey.groupListNav.text));
      expect(find.text(MessageKey.activeBadge.text), findsOneWidget);
      await unmountGrouPay(tester);
    });

    testWidgets('none active: "לא עכשיו" leaves no Active group', (
      tester,
    ) async {
      await pumpGrouPay(tester, db);
      await createUpToSheet(tester, 'Budapest');
      await tapAndSettle(tester, inSheet(MessageKey.activeSheetDecline.text));
      expectStage2();
      expect(await activeName(), isNull);
      await unmountGrouPay(tester);
    });

    testWidgets('Eilat active: the warning names it; "כן" switches', (
      tester,
    ) async {
      final eilat = await seed('Eilat');
      await repo.setActive(id: eilat.id);
      await pumpGrouPay(tester, db);
      await createUpToSheet(tester, 'Budapest');
      expect(inSheet(warning('Eilat')), findsOneWidget);
      // Not applied before the answer.
      expect(await activeName(), 'Eilat');

      await tapAndSettle(tester, inSheet(MessageKey.activeSheetConfirm.text));
      expectStage2();
      expect(await activeName(), 'Budapest');
      await unmountGrouPay(tester);
    });

    for (final (label, dismiss)
        in <(String, Future<void> Function(WidgetTester))>[
          (
            '"לא עכשיו"',
            (t) async {
              await t.tap(inSheet(MessageKey.activeSheetDecline.text));
              await t.pumpAndSettle();
            },
          ),
          (
            'the scrim',
            (t) async {
              await t.tapAt(const Offset(10, 10));
              await t.pumpAndSettle();
            },
          ),
          (
            'system back',
            (t) async {
              await t.binding.handlePopRoute();
              await t.pumpAndSettle();
            },
          ),
        ]) {
      testWidgets('Eilat active: $label keeps Eilat and opens stage 2', (
        tester,
      ) async {
        final eilat = await seed('Eilat');
        await repo.setActive(id: eilat.id);
        await pumpGrouPay(tester, db);
        await createUpToSheet(tester, 'Budapest');
        await dismiss(tester);
        expectStage2();
        expect(find.byType(CreateGroupScreen), findsOneWidget);
        expect(await activeName(), 'Eilat');
        await unmountGrouPay(tester);
      });
    }
  });

  group('The Active toggle in Group settings (FR-8)', () {
    Finder toggle() => find.byType(Switch);

    bool toggleValue(WidgetTester tester) =>
        tester.widget<Switch>(toggle()).value;

    Future<void> openSettings(WidgetTester tester, String groupId) async {
      await pumpGrouPay(tester, db, initialLocation: '/group/$groupId');
      await tapAndSettle(tester, find.text(MessageKey.groupSettingsChip.text));
      expect(find.byType(GroupSettingsScreen), findsOneWidget);
      expect(find.text(MessageKey.activeToggle.text), findsOneWidget);
    }

    testWidgets('none active: on at once with no sheet; off unsets', (
      tester,
    ) async {
      final budapest = await seed('Budapest');
      await openSettings(tester, budapest.id);
      expect(toggleValue(tester), isFalse);

      await tapAndSettle(tester, toggle());
      expect(sheet(), findsNothing);
      expect(toggleValue(tester), isTrue);
      expect(await activeName(), 'Budapest');

      await tapAndSettle(tester, toggle());
      expect(sheet(), findsNothing);
      expect(toggleValue(tester), isFalse);
      expect(await activeName(), isNull);

      // The list has no "⭐ פעילה".
      await tapAndSettle(tester, find.bySemanticsLabel(MessageKey.back.text));
      await tapAndSettle(tester, find.text(MessageKey.groupListNav.text));
      expect(find.text(MessageKey.activeBadge.text), findsNothing);
      await unmountGrouPay(tester);
    });

    testWidgets('Eilat active: the sheet; cancel keeps the toggle off', (
      tester,
    ) async {
      final eilat = await seed('Eilat');
      final budapest = await seed('Budapest');
      await repo.setActive(id: eilat.id);
      await openSettings(tester, budapest.id);

      await tapAndSettle(tester, toggle());
      expect(inSheet(MessageKey.activeSheetTitle.text), findsOneWidget);
      expect(inSheet(warning('Eilat')), findsOneWidget);
      // The toggle stays off until "כן".
      expect(toggleValue(tester), isFalse);

      await tapAndSettle(tester, inSheet(MessageKey.activeSheetDecline.text));
      expect(sheet(), findsNothing);
      expect(toggleValue(tester), isFalse);
      expect(await activeName(), 'Eilat');

      await tapAndSettle(tester, find.text(MessageKey.activeToggle.text));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(toggleValue(tester), isFalse);
      expect(await activeName(), 'Eilat');

      await tapAndSettle(tester, toggle());
      await tapAndSettle(tester, inSheet(MessageKey.activeSheetConfirm.text));
      expect(toggleValue(tester), isTrue);
      expect(await activeName(), 'Budapest');
      await unmountGrouPay(tester);
    });
  });

  group('Archive and restore (FR-6)', () {
    Future<void> archiveFromSettings(WidgetTester tester) async {
      await tapAndSettle(tester, find.text(MessageKey.groupSettingsChip.text));
      await tapAndSettle(tester, find.text(MessageKey.archiveAction.text));
      expect(
        inSheet(
          MessageKey.archiveSheetTitle.fill({'group': isolateName('Budapest')}),
        ),
        findsOneWidget,
      );
      expect(inSheet(MessageKey.archiveSheetBody.text), findsOneWidget);
      // Not destructive: the confirm is the orange primary.
      final confirm = find.widgetWithText(
        FilledButton,
        MessageKey.archiveSheetConfirm.text,
      );
      expect(confirm, findsOneWidget);
      expect(tester.widget<FilledButton>(confirm).style, isNull);
      await tapAndSettle(tester, confirm);
    }

    testWidgets('"ביטול", the scrim and back change nothing', (tester) async {
      final budapest = await seed('Budapest', ['Dana']);
      await repo.setActive(id: budapest.id);
      await pumpGrouPay(tester, db, initialLocation: '/group/${budapest.id}');
      await tapAndSettle(tester, find.text(MessageKey.groupSettingsChip.text));

      await tapAndSettle(tester, find.text(MessageKey.archiveAction.text));
      await tapAndSettle(tester, inSheet(MessageKey.cancel.text));
      await tapAndSettle(tester, find.text(MessageKey.archiveAction.text));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text(MessageKey.archiveAction.text));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(GroupSettingsScreen), findsOneWidget);
      expect((await repo.readGroup(budapest.id))!.isArchived, isFalse);
      expect(await activeName(), 'Budapest');
      await unmountGrouPay(tester);
    });

    testWidgets(
      'archive → list → Archive → read-only page → restore → editable',
      (tester) async {
        await seed('Eilat');
        final budapest = await seed('Budapest', ['Dana', 'Yossi']);
        await repo.setActive(id: budapest.id);
        await pumpGrouPay(tester, db, initialLocation: '/group/${budapest.id}');
        expect(
          find.text(MessageKey.archiveLink.fill({'n': '0'})),
          findsNothing,
        );

        await archiveFromSettings(tester);

        // Lands on the group list: Budapest is gone and not active.
        expect(find.byType(GroupListScreen), findsOneWidget);
        expect(find.text('Budapest'), findsNothing);
        expect(find.text(MessageKey.activeBadge.text), findsNothing);
        expect(await activeName(), isNull);
        final link = find.text(MessageKey.archiveLink.fill({'n': '1'}));
        expect(link, findsOneWidget);

        // The Archive view: nav, title, a gray card with "↩ שחזור".
        await tapAndSettle(tester, link);
        expect(find.byType(ArchiveScreen), findsOneWidget);
        expect(find.text(MessageKey.archiveBackNav.text), findsOneWidget);
        // The nav is the chevron icon + label, white on the gradient.
        final chevron = find.descendant(
          of: find.byType(ArchiveScreen),
          matching: find.byIcon(Icons.chevron_right),
        );
        expect(chevron, findsOneWidget);
        expect(find.textContaining('→'), findsNothing);
        expect(tester.widget<Icon>(chevron).color, AppColors.onHeader);
        expect(
          tester
              .widget<Text>(find.text(MessageKey.archiveBackNav.text))
              .style!
              .color,
          AppColors.onHeader,
        );
        expect(find.text(MessageKey.archiveTitle.text), findsOneWidget);
        expect(find.byType(ArchivedGroupCard), findsOneWidget);
        expect(find.text(MessageKey.restore.text), findsOneWidget);

        // The card opens the read-only page.
        await tapAndSettle(tester, find.text('Budapest'));
        expect(find.byType(GroupPage), findsOneWidget);
        expect(find.text(MessageKey.archiveNav.text), findsOneWidget);
        expect(find.text(MessageKey.archivedBadge.text), findsOneWidget);
        expect(find.text(MessageKey.groupSettingsChip.text), findsNothing);
        final note = find.text(MessageKey.archiveNote.text);
        final restore = find.text(MessageKey.restoreFromArchive.text);
        expect(note, findsOneWidget);
        expect(restore, findsOneWidget);
        // The note sits directly above the bar.
        expect(
          tester.getBottomLeft(note).dy,
          lessThan(tester.getTopLeft(restore).dy),
        );

        // The "ארכיון" nav returns to the Archive view, and back again.
        await tapAndSettle(tester, find.text(MessageKey.archiveNav.text));
        expect(find.byType(ArchiveScreen), findsOneWidget);
        await tapAndSettle(tester, find.text('Budapest'));

        // Restore: the same Group page, editable, not active.
        await tapAndSettle(tester, restore);
        expect(find.byType(GroupPage), findsOneWidget);
        expect(find.text(MessageKey.archivedBadge.text), findsNothing);
        expect(find.text(MessageKey.archiveNote.text), findsNothing);
        expect(find.text(MessageKey.groupSettingsChip.text), findsOneWidget);
        expect(find.text(MessageKey.groupListNav.text), findsOneWidget);
        expect(find.text('2 משתתפים · 0 הוצאות'), findsOneWidget);
        expect(await activeName(), isNull);

        // Back leads to the group list, with no Archive link.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(GroupListScreen), findsOneWidget);
        expect(find.text('Budapest'), findsOneWidget);
        expect(find.textContaining('🗂 ארכיון'), findsNothing);
        await unmountGrouPay(tester);
      },
    );

    testWidgets('"↩ שחזור" on a card restores and opens the page', (
      tester,
    ) async {
      final budapest = await seed('Budapest', ['Dana']);
      await repo.archive(id: budapest.id);
      await pumpGrouPay(tester, db, initialLocation: '/archive');

      await tapAndSettle(tester, find.text(MessageKey.restore.text));
      expect(find.byType(GroupPage), findsOneWidget);
      expect(find.text(MessageKey.groupSettingsChip.text), findsOneWidget);
      expect((await repo.readGroup(budapest.id))!.isArchived, isFalse);
      expect(await activeName(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(GroupListScreen), findsOneWidget);
      await unmountGrouPay(tester);
    });

    testWidgets('settings of an Archived group redirects to its page', (
      tester,
    ) async {
      final budapest = await seed('Budapest');
      await repo.archive(id: budapest.id);
      await pumpGrouPay(
        tester,
        db,
        initialLocation: '/group/${budapest.id}/settings',
      );
      expect(find.byType(GroupSettingsScreen), findsNothing);
      expect(find.byType(GroupPage), findsOneWidget);
      expect(find.text(MessageKey.archivedBadge.text), findsOneWidget);
      await unmountGrouPay(tester);
    });

    testWidgets('an Archived group on /group/:id is read-only too', (
      tester,
    ) async {
      final budapest = await seed('Budapest');
      await repo.archive(id: budapest.id);
      await pumpGrouPay(tester, db, initialLocation: '/group/${budapest.id}');
      expect(find.text(MessageKey.archivedBadge.text), findsOneWidget);
      expect(find.text(MessageKey.groupSettingsChip.text), findsNothing);
      expect(find.text(MessageKey.restoreFromArchive.text), findsOneWidget);
      await unmountGrouPay(tester);
    });
  });

  testWidgets('the Active card has the start edge and the badge', (
    tester,
  ) async {
    final eilat = await seed('Eilat');
    await seed('Budapest');
    await repo.setActive(id: eilat.id);
    await pumpGrouPay(tester, db);

    final cards = find.byType(GroupCard);
    expect(cards, findsNWidgets(2));
    // The Active group is first even though Budapest is newer.
    expect(tester.widget<GroupCard>(cards.first).item.group.name, 'Eilat');
    expect(
      find.descendant(
        of: cards.first,
        matching: find.text(MessageKey.activeBadge.text),
      ),
      findsOneWidget,
    );
    expect(find.text(MessageKey.activeBadge.text), findsOneWidget);
    await unmountGrouPay(tester);
  });
}
