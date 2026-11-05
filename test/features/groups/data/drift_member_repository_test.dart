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
import '../../../support/uuid_v7.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late FakePayerUsage payerUsage;
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
    payerUsage = FakePayerUsage();
    repo = DriftMemberRepository(db, clock, payerUsage);
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

  test('readMembers returns the Members in memberSeq order', () async {
    expect(await repo.readMembers(groupId), isEmpty);
    final dana = await added('Dana');
    final yossi = await added('Yossi');
    final other = await createGroup('Rome');
    await repo.addMember(id: newId(), groupId: other, name: 'Noa');
    final noa = await added('Noa');
    expect(await repo.readMembers(groupId), [dana, yossi, noa]);
    await repo.renameMember(id: dana.id, name: 'Zoe');
    expect((await repo.readMembers(groupId)).map((m) => m.name), [
      'Zoe',
      'Yossi',
      'Noa',
    ]);
  });

  group('renameMember', () {
    Future<Result<Member>> rename(Member m, String name) =>
        repo.renameMember(id: m.id, name: name);

    Future<MemberRow> rowOf(Member m) =>
        (db.select(db.members)..where((r) => r.id.equals(m.id))).getSingle();

    test('"Dana" → "Danna": name, nameKey and modifiedAt change; '
        'createdAt and memberSeq do not', () async {
      clock.now = 1000;
      final dana = await added('Dana');
      clock.now = 5000;
      final result = await rename(dana, 'Danna');

      final renamed = (result as Ok<Member>).value;
      expect(renamed.name, 'Danna');
      expect(renamed.modifiedAt, 5000);
      final row = await rowOf(dana);
      expect(row.name, 'Danna');
      expect(row.nameKey, 'danna');
      expect(row.modifiedAt, 5000);
      expect(row.createdAt, 1000);
      expect(row.memberSeq, dana.memberSeq);
      expect(await members(), [renamed]);
    });

    test('case-only "dana" → "Dana" is saved', () async {
      final dana = await added('dana');
      expect((await rename(dana, 'Dana')).isOk, isTrue);
      expect((await rowOf(dana)).name, 'Dana');
    });

    test('unchanged "Dana" → " Dana " is Ok and writes nothing', () async {
      clock.now = 1000;
      final dana = await added('Dana');
      clock.now = 5000;
      expect(await rename(dana, ' Dana '), Ok(dana));
      expect((await rowOf(dana)).modifiedAt, 1000);
    });

    for (final blank in ['', '   ']) {
      test('"Dana" → "$blank": nameRequired, name stays', () async {
        final dana = await added('Dana');
        expect(
          await rename(dana, blank),
          const Failure<Member>(MessageKey.nameRequired),
        );
        expect((await rowOf(dana)).name, 'Dana');
      });
    }

    test('"Dana" → "yossi" when "Yossi" exists: memberNameTaken', () async {
      final dana = await added('Dana');
      await added('Yossi');
      expect(
        await rename(dana, 'yossi'),
        const Failure<Member>(MessageKey.memberNameTaken),
      );
      expect((await rowOf(dana)).name, 'Dana');
    });

    test('a name used in another Group is allowed', () async {
      final dana = await added('Dana');
      final otherId = await createGroup('Budapest');
      await repo.addMember(id: newId(), groupId: otherId, name: 'Yossi');
      expect((await rename(dana, 'Yossi')).isOk, isTrue);
    });

    test('the name is trimmed and cut to 10 grapheme clusters', () async {
      final dana = await added('Dana');
      final result = await rename(dana, ' Alexandrina ');
      expect((result as Ok<Member>).value.name, 'Alexandrin');
    });
  });

  group('removeMember', () {
    test('no Expenses: "Dana" is deleted', () async {
      final dana = await added('Dana');
      final yossi = await added('Yossi');
      expect((await repo.removeMember(id: dana.id)).isOk, isTrue);
      expect(await members(), [yossi]);
      // The port was asked inside the removal.
      expect(payerUsage.calls, [(groupId, dana.id)]);
    });

    test('a Payer is refused with memberIsPayer; nothing removed', () async {
      final yossi = await added('Yossi');
      payerUsage.payers.add(yossi.id);
      expect(
        await repo.removeMember(id: yossi.id),
        const Failure<void>(MessageKey.memberIsPayer),
      );
      expect(await members(), [yossi]);
    });

    test('a Member that no longer exists: Ok, nothing written', () async {
      final dana = await added('Dana');
      expect((await repo.removeMember(id: dana.id)).isOk, isTrue);
      expect((await repo.removeMember(id: dana.id)).isOk, isTrue);
      expect(await members(), isEmpty);
      // The second call did not reach the port.
      expect(payerUsage.calls, hasLength(1));
    });
  });
}
