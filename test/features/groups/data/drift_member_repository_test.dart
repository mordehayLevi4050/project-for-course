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
import '../../../support/uuid_v7.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late DriftMemberRepository repo;
  late String groupId;

  Future<String> createGroup(String name) async {
    final result = await DriftGroupRepository(
      db,
      clock,
    ).createGroup(id: newId(), name: name);
    return (result as Ok<Group>).value.id;
  }

  setUp(() async {
    db = AppDatabase.memory();
    clock = FakeClock(1000);
    repo = DriftMemberRepository(db, clock);
    groupId = await createGroup('Eilat');
  });
  tearDown(() => db.close());

  Future<Result<Member>> add(String name, {String? id}) =>
      repo.addMember(id: id ?? newId(), groupId: groupId, name: name);

  Future<Member> added(String name) async => (await add(name) as Ok).value;

  Future<List<Member>> members() => repo.watchMembers(groupId).first;

  test('adding "Dana" saves her with memberSeq 1', () async {
    final dana = await added('Dana');
    expect(dana.name, 'Dana');
    expect(dana.memberSeq, 1);
    expect(await members(), [dana]);
  });

  for (final blank in ['', '   ']) {
    test('blank name "$blank": nameRequired, nothing written', () async {
      expect(await add(blank), const Failure<Member>(MessageKey.nameRequired));
      expect(await members(), isEmpty);
    });
  }

  for (final dup in ['Dana', ' dana ']) {
    test('"$dup" when "Dana" exists: memberNameTaken', () async {
      await add('Dana');
      expect(await add(dup), const Failure<Member>(MessageKey.memberNameTaken));
      expect(await members(), hasLength(1));
    });
  }

  test('the same name in another Group is allowed', () async {
    await add('Dana');
    final otherId = await createGroup('Budapest');
    final result = await repo.addMember(
      id: newId(),
      groupId: otherId,
      name: 'Dana',
    );
    expect(result.isOk, isTrue);
  });

  test('11th Member "Gil": membersLimit, nothing written', () async {
    for (var i = 1; i <= 10; i++) {
      expect((await add('M$i')).isOk, isTrue);
    }
    expect(await add('Gil'), const Failure<Member>(MessageKey.membersLimit));
    expect(await members(), hasLength(10));
  });

  test('seqs [1, 2] → the new Member gets 3', () async {
    await add('A');
    await add('B');
    expect((await added('C')).memberSeq, 3);
  });

  test('the 7th Member gets seq 7 (color index 0)', () async {
    for (final n in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await add(n);
    }
    expect((await added('G')).memberSeq, 7);
  });

  test('seq is MAX + 1 and set once: a removed Member frees no seq', () async {
    await add('A');
    final b = await added('B');
    await added('C');
    await (db.delete(db.members)..where((m) => m.id.equals(b.id))).go();
    expect((await added('D')).memberSeq, 4);
  });

  test('members are ordered by memberSeq', () async {
    await add('Yossi');
    await add('Avi');
    await add('Dana');
    expect([for (final m in await members()) m.name], ['Yossi', 'Avi', 'Dana']);
  });

  test('double tap with the same form id: exactly 1 Member', () async {
    final id = newId();
    final results = await Future.wait([
      add('Dana', id: id),
      add('Dana', id: id),
    ]);
    expect(results.every((r) => r.isOk), isTrue);
    expect(await members(), hasLength(1));
  });

  test('name is trimmed and cut to 10 grapheme clusters', () async {
    expect((await added(' Alexandrina ')).name, 'Alexandrin');
  });

  test('UUID v7 id; createdAt set once, modifiedAt on insert', () async {
    clock.now = 7000;
    final id = newId();
    final m = (await add('Dana', id: id) as Ok<Member>).value;
    expect(m.id, matches(uuidV7));
    expect(m.createdAt, 7000);
    expect(m.modifiedAt, 7000);

    clock.now = 9000;
    expect((await add('Dana', id: id)).isOk, isTrue);
    final row = await db.select(db.members).getSingle();
    expect(row.createdAt, 7000);
    expect(row.modifiedAt, 7000);
  });
}
