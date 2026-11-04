import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/member.dart';

import '../../../support/fake_clock.dart';
import '../../../support/fake_payer_usage.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late DriftGroupRepository repo;
  late DriftMemberRepository members;

  setUp(() {
    db = AppDatabase.memory();
    clock = FakeClock(1000);
    repo = DriftGroupRepository(db, clock);
    members = DriftMemberRepository(db, clock, FakePayerUsage());
  });
  tearDown(() => db.close());

  Future<Group> create(String name) async =>
      ((await repo.createGroup(id: newId(), name: name)) as Ok<Group>).value;

  Future<Member> addMember(String groupId, String name) async =>
      ((await members.addMember(
        id: newId(),
        groupId: groupId,
        name: name,
      )) as Ok<Member>).value;

  Future<String?> activeId() => repo.readActiveGroupId();

  Future<GroupRow> row(String id) =>
      (db.select(db.groups)..where((g) => g.id.equals(id))).getSingle();

  Future<List<String>> listNames() async => [
    for (final item in await repo.watchGroups().first) item.group.name,
  ];

  Future<List<String>> archivedNames() async => [
    for (final item in await repo.watchArchivedGroups().first) item.group.name,
  ];

  group('Active group (FR-7, FR-8)', () {
    test('none is set at first', () async {
      await create('Eilat');
      expect(await activeId(), isNull);
      expect(await repo.watchActiveGroupId().first, isNull);
      expect(await db.select(db.appSettings).get(), isEmpty);
    });

    test('setActive with none active: that Group is active', () async {
      final budapest = await create('Budapest');
      expect(await repo.setActive(id: budapest.id), const Ok<void>(null));
      expect(await activeId(), budapest.id);
      expect(await repo.watchActiveGroupId().first, budapest.id);
    });

    test('setActive with Eilat active: only Budapest is active', () async {
      final eilat = await create('Eilat');
      final budapest = await create('Budapest');
      await repo.setActive(id: eilat.id);
      await repo.setActive(id: budapest.id);
      expect(await activeId(), budapest.id);
      // One settings row: at most one Active group.
      expect(await db.select(db.appSettings).get(), hasLength(1));
      final flags = {
        for (final item in await repo.watchGroups().first)
          item.group.name: item.isActive,
      };
      expect(flags, {'Budapest': true, 'Eilat': false});
    });

    test('the list puts the Active group first, then newest first', () async {
      final a = await create('A');
      await create('B');
      await create('C');
      expect(await listNames(), ['C', 'B', 'A']);
      await repo.setActive(id: a.id);
      expect(await listNames(), ['A', 'C', 'B']);
    });

    test('unsetActive clears the Active group', () async {
      final budapest = await create('Budapest');
      await repo.setActive(id: budapest.id);
      expect(await repo.unsetActive(id: budapest.id), const Ok<void>(null));
      expect(await activeId(), isNull);
      final items = await repo.watchGroups().first;
      expect(items.any((i) => i.isActive), isFalse);
    });

    test('unsetActive of a Group that is not active writes nothing', () async {
      final eilat = await create('Eilat');
      final budapest = await create('Budapest');
      await repo.setActive(id: eilat.id);
      await repo.unsetActive(id: budapest.id);
      expect(await activeId(), eilat.id);
    });

    test('setActive on an Archived group: Failure(groupArchived)', () async {
      final eilat = await create('Eilat');
      final budapest = await create('Budapest');
      await repo.setActive(id: eilat.id);
      await repo.archive(id: budapest.id);
      expect(
        await repo.setActive(id: budapest.id),
        const Failure<void>(MessageKey.groupArchived),
      );
      expect(await activeId(), eilat.id);
    });

    test('setActive of an unknown Group is a bug', () async {
      await expectLater(repo.setActive(id: 'missing'), throwsStateError);
    });
  });

  group('Archive (FR-6)', () {
    test(
      'archiving the Active group clears it in the same transaction',
      () async {
        final budapest = await create('Budapest');
        await repo.setActive(id: budapest.id);
        clock.now = 5000;
        expect(await repo.archive(id: budapest.id), const Ok<void>(null));

        expect((await row(budapest.id)).archivedAt, 5000);
        expect(await activeId(), isNull);
        expect(await listNames(), isEmpty);
        expect(await archivedNames(), ['Budapest']);
        final archived = (await repo.watchArchivedGroups().first).single;
        expect(archived.isActive, isFalse);
        expect(archived.group.isArchived, isTrue);
      },
    );

    test('archiving another Group keeps the Active group', () async {
      final eilat = await create('Eilat');
      final budapest = await create('Budapest');
      await repo.setActive(id: eilat.id);
      await repo.archive(id: budapest.id);
      expect(await activeId(), eilat.id);
    });

    test('a failed step rolls the whole archive back', () async {
      final budapest = await create('Budapest');
      await repo.setActive(id: budapest.id);
      // Breaks the second write of the transaction.
      await db.customStatement(
        'CREATE TRIGGER fail_clear BEFORE UPDATE ON app_settings '
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      await expectLater(repo.archive(id: budapest.id), throwsA(anything));
      expect((await row(budapest.id)).archivedAt, isNull);
      expect(await activeId(), budapest.id);
    });

    test('the Archive view lists archived Groups newest first', () async {
      final a = await create('A');
      final b = await create('B');
      await create('C');
      await repo.archive(id: b.id);
      await repo.archive(id: a.id);
      expect(await archivedNames(), ['B', 'A']);
      expect(await listNames(), ['C']);
    });

    test('archiving twice: Failure(groupArchived), nothing written', () async {
      final budapest = await create('Budapest');
      await repo.archive(id: budapest.id);
      final before = await row(budapest.id);
      clock.now = 9000;
      expect(
        await repo.archive(id: budapest.id),
        const Failure<void>(MessageKey.groupArchived),
      );
      expect(await row(budapest.id), before);
    });

    test('restoring a Group that is not archived: Failure', () async {
      final budapest = await create('Budapest');
      final before = await row(budapest.id);
      expect(
        await repo.restore(id: budapest.id),
        const Failure<void>(MessageKey.groupNotArchived),
      );
      expect(await row(budapest.id), before);
    });

    test('restore: Members unchanged, not active, editable again', () async {
      final budapest = await create('Budapest');
      await addMember(budapest.id, 'Dana');
      await addMember(budapest.id, 'Yossi');
      await repo.setActive(id: budapest.id);
      final before = await row(budapest.id);
      final membersBefore = await db.select(db.members).get();

      await repo.archive(id: budapest.id);
      expect(await repo.restore(id: budapest.id), const Ok<void>(null));

      expect(await row(budapest.id), before);
      expect(await db.select(db.members).get(), membersBefore);
      expect(await activeId(), isNull);
      expect(await listNames(), ['Budapest']);
      expect(await archivedNames(), isEmpty);
      expect(
        (await repo.renameGroup(id: budapest.id, name: 'Pest')).isOk,
        isTrue,
      );
    });

    test('a name taken by an Archived group: groupNameTaken', () async {
      final budapest = await create('Budapest');
      await repo.archive(id: budapest.id);
      expect(
        await repo.createGroup(id: newId(), name: 'budapest'),
        const Failure<Group>(MessageKey.groupNameTaken),
      );
      expect(await db.select(db.groups).get(), hasLength(1));
    });

    test('readGroup reports isArchived, and null when missing', () async {
      final budapest = await create('Budapest');
      expect((await repo.readGroup(budapest.id))!.isArchived, isFalse);
      await repo.archive(id: budapest.id);
      expect((await repo.readGroup(budapest.id))!.isArchived, isTrue);
      expect(await repo.readGroup('missing'), isNull);
    });

    test('archive and restore of an unknown Group are bugs', () async {
      await expectLater(repo.archive(id: 'missing'), throwsStateError);
      await expectLater(repo.restore(id: 'missing'), throwsStateError);
    });
  });

  group('Writes on an Archived group return Failure(groupArchived)', () {
    late Group budapest;
    late Member dana;

    setUp(() async {
      budapest = await create('Budapest');
      dana = await addMember(budapest.id, 'Dana');
      await repo.archive(id: budapest.id);
    });

    test('renameGroup', () async {
      final before = await row(budapest.id);
      expect(
        await repo.renameGroup(id: budapest.id, name: 'Pest'),
        const Failure<Group>(MessageKey.groupArchived),
      );
      expect(await row(budapest.id), before);
    });

    test('addMember', () async {
      expect(
        await members.addMember(
          id: newId(),
          groupId: budapest.id,
          name: 'Yossi',
        ),
        const Failure<Member>(MessageKey.groupArchived),
      );
      expect(await db.select(db.members).get(), hasLength(1));
    });

    test('renameMember', () async {
      expect(
        await members.renameMember(id: dana.id, name: 'Danna'),
        const Failure<Member>(MessageKey.groupArchived),
      );
      expect((await db.select(db.members).getSingle()).name, 'Dana');
    });

    test('removeMember', () async {
      expect(
        await members.removeMember(id: dana.id),
        const Failure<void>(MessageKey.groupArchived),
      );
      expect(await db.select(db.members).get(), hasLength(1));
    });

    test('setActive', () async {
      expect(
        await repo.setActive(id: budapest.id),
        const Failure<void>(MessageKey.groupArchived),
      );
      expect(await activeId(), isNull);
    });
  });

  group('app_settings schema', () {
    test('holds a single row: id must be 1', () async {
      await expectLater(
        db
            .into(db.appSettings)
            .insert(const AppSettingsCompanion(id: Value(2))),
        throwsA(anything),
      );
    });

    test('activeGroupId must reference an existing Group', () async {
      await expectLater(
        db
            .into(db.appSettings)
            .insert(
              const AppSettingsCompanion(
                id: Value(1),
                activeGroupId: Value('missing'),
              ),
            ),
        throwsA(anything),
      );
    });
  });
}
