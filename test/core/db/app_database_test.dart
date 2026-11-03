import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  Future<void> insertGroup(String id, String name) => db
      .into(db.groups)
      .insert(
        GroupsCompanion.insert(
          id: id,
          name: name,
          nameKey: name.toLowerCase(),
          createdAt: 1,
          modifiedAt: 1,
        ),
      );

  Future<void> insertMember(String id, String groupId, String name, int seq) =>
      db
          .into(db.members)
          .insert(
            MembersCompanion.insert(
              id: id,
              groupId: groupId,
              name: name,
              nameKey: name.toLowerCase(),
              memberSeq: seq,
              createdAt: 1,
              modifiedAt: 1,
            ),
          );

  Future<int> pragma(String name) async =>
      (await db.customSelect('PRAGMA $name').getSingle()).data.values.first
          as int;

  test('schemaVersion is 1', () {
    expect(db.schemaVersion, 1);
  });

  test('beforeOpen turns on foreign keys and synchronous = FULL', () async {
    expect(await pragma('foreign_keys'), 1);
    expect(await pragma('synchronous'), 2); // 2 = FULL
  });

  test('groups.nameKey is unique', () async {
    await insertGroup('g1', 'Budapest');
    await expectLater(insertGroup('g2', 'budapest'), throwsA(isA<Exception>()));
  });

  test('members (groupId, nameKey) is unique within a Group only', () async {
    await insertGroup('g1', 'Budapest');
    await insertGroup('g2', 'Eilat');
    await insertMember('m1', 'g1', 'Dana', 1);
    await expectLater(
      insertMember('m2', 'g1', 'DANA', 2),
      throwsA(isA<Exception>()),
    );
    await insertMember('m3', 'g2', 'Dana', 1); // another Group: allowed
  });

  test('members (groupId, memberSeq) is unique', () async {
    await insertGroup('g1', 'Budapest');
    await insertMember('m1', 'g1', 'Dana', 1);
    await expectLater(
      insertMember('m2', 'g1', 'Yossi', 1),
      throwsA(isA<Exception>()),
    );
  });

  test('a Member must belong to an existing Group', () async {
    await expectLater(
      insertMember('m1', 'missing', 'Dana', 1),
      throwsA(isA<Exception>()),
    );
  });

  test('UNIQUE(groupId, id) exists on members for the expenses FK', () async {
    final indexes = await db.customSelect("PRAGMA index_list('members')").get();
    final columnSets = <String>[];
    for (final index in indexes) {
      if (index.read<int>('unique') != 1) continue;
      final cols = await db
          .customSelect("PRAGMA index_info('${index.read<String>('name')}')")
          .get();
      columnSets.add(
        (cols.map((c) => c.read<String>('name')).toList()..sort()).join(','),
      );
    }
    expect(columnSets, contains('group_id,id'));
    expect(columnSets, contains('group_id,name_key'));
    expect(columnSets, contains('group_id,member_seq'));
  });

  test('rows map to GroupRow and MemberRow', () async {
    await insertGroup('g1', 'Budapest');
    await insertMember('m1', 'g1', 'Dana', 1);
    final GroupRow group = await db.select(db.groups).getSingle();
    final MemberRow member = await db.select(db.members).getSingle();
    expect(group.name, 'Budapest');
    expect(member.memberSeq, 1);
    expect(member.groupId, 'g1');
  });
}
