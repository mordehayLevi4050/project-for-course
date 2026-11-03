import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';

import '../../../support/fake_clock.dart';
import '../../../support/uuid_v7.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late DriftGroupRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    clock = FakeClock(1000);
    repo = DriftGroupRepository(db, clock);
  });
  tearDown(() => db.close());

  Future<Group> create(String name) async =>
      ((await repo.createGroup(id: newId(), name: name)) as Ok<Group>).value;

  Future<int> groupCount() async => (await db.select(db.groups).get()).length;

  test('Create "Trip to Eilat": one Group, listed with 0 Members', () async {
    final result = await repo.createGroup(id: newId(), name: 'Trip to Eilat');
    expect(result.isOk, isTrue);
    expect(await groupCount(), 1);

    final list = await repo.watchGroups().first;
    expect(list, hasLength(1));
    expect(list.single.group.name, 'Trip to Eilat');
    expect(list.single.memberCount, 0);
  });

  test('the list carries the Member count of each Group', () async {
    final eilat = await create('Eilat');
    await create('Budapest');
    final members = DriftMemberRepository(db, clock);
    await members.addMember(id: newId(), groupId: eilat.id, name: 'Dana');
    await members.addMember(id: newId(), groupId: eilat.id, name: 'Yossi');

    final counts = {
      for (final item in await repo.watchGroups().first)
        item.group.name: item.memberCount,
    };
    expect(counts, {'Eilat': 2, 'Budapest': 0});
  });

  for (final blank in ['', '   ']) {
    test('blank name "$blank": nameRequired, nothing written', () async {
      expect(
        await repo.createGroup(id: newId(), name: blank),
        const Failure<Group>(MessageKey.nameRequired),
      );
      expect(await groupCount(), 0);
    });
  }

  test('" budapest " when "Budapest" exists: groupNameTaken', () async {
    await create('Budapest');
    expect(
      await repo.createGroup(id: newId(), name: ' budapest '),
      const Failure<Group>(MessageKey.groupNameTaken),
    );
    expect(await groupCount(), 1);
  });

  test('double tap with the same form id: exactly 1 Group, no error', () async {
    final id = newId();
    final results = await Future.wait([
      repo.createGroup(id: id, name: 'Eilat'),
      repo.createGroup(id: id, name: 'Eilat'),
    ]);
    expect(results.every((r) => r.isOk), isTrue);
    expect(await groupCount(), 1);

    // A later repeat is still Ok and writes nothing.
    clock.now = 5000;
    final again = await repo.createGroup(id: id, name: 'Eilat');
    expect((again as Ok<Group>).value.createdAt, 1000);
    expect(await groupCount(), 1);
  });

  test('Create A, then B: the list shows B, then A', () async {
    final a = await create('A');
    final b = await create('B');
    expect(a.groupSeq, 1);
    expect(b.groupSeq, 2);
    final names = [
      for (final item in await repo.watchGroups().first) item.group.name,
    ];
    expect(names, ['B', 'A']);
  });

  test('the list is ordered by groupSeq, not by clock', () async {
    clock.now = 9000;
    await create('First');
    clock.now = 1; // the clock went backwards
    await create('Second');
    final names = [
      for (final item in await repo.watchGroups().first) item.group.name,
    ];
    expect(names, ['Second', 'First']);
  });

  test('name is trimmed and cut to 20 grapheme clusters on save', () async {
    final g = await create('  ${'x' * 25}  ');
    expect(g.name, 'x' * 20);
  });

  test('UUID v7 id; createdAt and modifiedAt set from the clock', () async {
    clock.now = 4242;
    final g = await create('Eilat');
    expect(g.id, matches(uuidV7));
    final row = await db.select(db.groups).getSingle();
    expect(row.id, g.id);
    expect(row.createdAt, 4242);
    expect(row.modifiedAt, 4242);
    expect(row.nameKey, 'eilat');
  });

  test('watchGroup emits the Group, and null for an unknown id', () async {
    final g = await create('Eilat');
    expect(await repo.watchGroup(g.id).first, g);
    expect(await repo.watchGroup('missing').first, isNull);
  });
}
