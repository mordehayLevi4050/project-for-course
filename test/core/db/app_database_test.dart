import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';

void main() {
  late AppDatabase db;

  var nextSeq = 1;

  setUp(() {
    db = AppDatabase.memory();
    nextSeq = 1;
  });
  tearDown(() => db.close());

  Future<void> insertGroup(String id, String name, {int? seq}) => db
      .into(db.groups)
      .insert(
        GroupsCompanion.insert(
          id: id,
          name: name,
          nameKey: name.toLowerCase(),
          groupSeq: seq ?? nextSeq++,
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

  test('schemaVersion is 3', () {
    expect(db.schemaVersion, 3);
  });

  test('beforeOpen turns on foreign keys and synchronous = FULL', () async {
    expect(await pragma('foreign_keys'), 1);
    expect(await pragma('synchronous'), 2); // 2 = FULL
  });

  test('groups.nameKey is unique', () async {
    await insertGroup('g1', 'Budapest');
    await expectLater(insertGroup('g2', 'budapest'), throwsA(isA<Exception>()));
  });

  test('groups.groupSeq is unique', () async {
    await insertGroup('g1', 'Budapest', seq: 1);
    await expectLater(
      insertGroup('g2', 'Eilat', seq: 1),
      throwsA(isA<Exception>()),
    );
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

  Future<void> insertExpense(
    String id,
    String groupId,
    String payerId, {
    int seq = 1,
  }) => db
      .into(db.expenses)
      .insert(
        ExpensesCompanion.insert(
          id: id,
          groupId: groupId,
          payerId: payerId,
          amount: 3000,
          category: 'hotel',
          saveSeq: seq,
          createdAt: 1,
          modifiedAt: 1,
        ),
      );

  test('expenses (groupId, saveSeq) is unique', () async {
    await insertGroup('g1', 'Budapest');
    await insertMember('m1', 'g1', 'Dana', 1);
    await insertExpense('e1', 'g1', 'm1', seq: 1);
    await expectLater(
      insertExpense('e2', 'g1', 'm1', seq: 1),
      throwsA(isA<Exception>()),
    );
  });

  test('an Expense Payer must be a Member of the same Group', () async {
    await insertGroup('g1', 'Budapest');
    await insertGroup('g2', 'Eilat');
    await insertMember('m1', 'g1', 'Dana', 1);
    await expectLater(
      insertExpense('e1', 'g2', 'm1'),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      insertExpense('e2', 'g1', 'missing'),
      throwsA(isA<Exception>()),
    );
  });

  test('ON DELETE RESTRICT keeps a Member who paid', () async {
    await insertGroup('g1', 'Budapest');
    await insertMember('m1', 'g1', 'Dana', 1);
    await insertMember('m2', 'g1', 'Yossi', 2);
    await insertExpense('e1', 'g1', 'm1');
    await expectLater(
      (db.delete(db.members)..where((m) => m.id.equals('m1'))).go(),
      throwsA(isA<Exception>()),
    );
    // A Member who paid for nothing can go.
    await (db.delete(db.members)..where((m) => m.id.equals('m2'))).go();
    expect(await db.select(db.members).get(), hasLength(1));
  });

  test('rows map to GroupRow and MemberRow', () async {
    await insertGroup('g1', 'Budapest');
    await insertMember('m1', 'g1', 'Dana', 1);
    final GroupRow group = await db.select(db.groups).getSingle();
    final MemberRow member = await db.select(db.members).getSingle();
    expect(group.name, 'Budapest');
    expect(group.groupSeq, 1);
    expect(member.memberSeq, 1);
    expect(member.groupId, 'g1');
  });
}
