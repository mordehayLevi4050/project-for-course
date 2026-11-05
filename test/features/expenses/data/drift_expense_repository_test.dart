import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/features/expenses/data/drift_expense_repository.dart';
import 'package:groupay/features/expenses/data/drift_group_totals.dart';
import 'package:groupay/features/expenses/data/drift_payer_usage.dart';
import 'package:groupay/features/expenses/domain/category.dart';
import 'package:groupay/features/expenses/domain/expense.dart';
import 'package:groupay/features/expenses/domain/group_snapshot.dart';
import 'package:groupay/features/groups/data/drift_group_repository.dart';
import 'package:groupay/features/groups/data/drift_member_repository.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/member.dart';

import '../../../support/fake_clock.dart';
import '../../../support/uuid_v7.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late DriftGroupRepository groups;
  late DriftMemberRepository members;
  late DriftExpenseRepository repo;

  setUp(() {
    db = AppDatabase.memory();
    clock = FakeClock(1000);
    groups = DriftGroupRepository(db, clock);
    members = DriftMemberRepository(db, clock, DriftPayerUsage(db));
    repo = DriftExpenseRepository(db, clock, members);
  });
  tearDown(() => db.close());

  Future<String> createGroup(String name) async => ((await groups.createGroup(
    id: newId(),
    name: name,
  )) as Ok<Group>).value.id;

  Future<Member> addMember(String groupId, String name) async =>
      ((await members.addMember(
        id: newId(),
        groupId: groupId,
        name: name,
      )) as Ok<Member>).value;

  /// A Group with Members Dana, Yossi and Noa, in that add order.
  Future<(String, Member, Member, Member)> seed([String name = 'Eilat']) async {
    final g = await createGroup(name);
    return (
      g,
      await addMember(g, 'Dana'),
      await addMember(g, 'Yossi'),
      await addMember(g, 'Noa'),
    );
  }

  Future<Result<Expense>> add(
    String groupId,
    Member payer,
    int tenths,
    Category category, {
    String? id,
    String? description,
  }) => repo.add(
    id: id ?? newId(),
    groupId: groupId,
    payerId: payer.id,
    amount: Tenths(tenths),
    category: category,
    description: description,
  );

  Future<List<Expense>> list(String groupId) =>
      repo.watchExpenses(groupId).first;

  test(
    'Dana, ₪300, Hotel is stored once with saveSeq 1 and the clock',
    () async {
      final (g, dana, _, _) = await seed();
      final id = newId();
      final result = await add(g, dana, 3000, Category.hotel, id: id);
      final expense = (result as Ok<Expense>).value;
      expect(expense.id, matches(uuidV7));
      expect(expense.id, id);
      expect(expense.payerId, dana.id);
      expect(expense.amount, const Tenths(3000));
      expect(expense.category, Category.hotel);
      expect(expense.description, isNull);
      expect(expense.saveSeq, 1);
      expect(expense.createdAt, 1000);
      expect(expense.modifiedAt, 1000);
      expect(await list(g), [expense]);

      final row = await db.select(db.expenses).getSingle();
      expect(row.category, 'hotel');
      expect(row.amount, 3000);
    },
  );

  test('a repeated save of the same form writes nothing', () async {
    final (g, dana, _, _) = await seed();
    final id = newId();
    final first = await add(g, dana, 3000, Category.hotel, id: id);
    clock.now = 2000;
    final second = await add(g, dana, 3000, Category.hotel, id: id);
    expect(second, first);
    expect(await db.select(db.expenses).get(), hasLength(1));
  });

  test('two concurrent saves of the same form store one Expense', () async {
    final (g, dana, _, _) = await seed();
    final id = newId();
    await Future.wait([
      add(g, dana, 3000, Category.hotel, id: id),
      add(g, dana, 3000, Category.hotel, id: id),
    ]);
    expect(await db.select(db.expenses).get(), hasLength(1));
  });

  for (final (label, tenths) in [
    ('0', 0),
    ('-50', -500),
    ('1,000,001', 10000010),
  ]) {
    test('Amount $label: invalidAmount, nothing written', () async {
      final (g, dana, _, _) = await seed();
      expect(
        await add(g, dana, tenths, Category.hotel),
        const Failure<Expense>(MessageKey.invalidAmount),
      );
      expect(await list(g), isEmpty);
    });
  }

  test('Amount ₪1,000,000 is saved', () async {
    final (g, dana, _, _) = await seed();
    expect((await add(g, dana, 10000000, Category.hotel)).isOk, isTrue);
  });

  for (final blank in [null, '', '   ']) {
    test('Other with Description "$blank": descriptionRequired', () async {
      final (g, dana, _, _) = await seed();
      expect(
        await add(g, dana, 500, Category.other, description: blank),
        const Failure<Expense>(MessageKey.descriptionRequired),
      );
      expect(await list(g), isEmpty);
    });
  }

  test('Other stores the trimmed Description, the row title', () async {
    final (g, dana, _, _) = await seed();
    final e = ((await add(
      g,
      dana,
      500,
      Category.other,
      description: ' Umbrella ',
    )) as Ok<Expense>).value;
    expect(e.description, 'Umbrella');
    expect(e.title, 'Umbrella');
  });

  test('a Description is stored only for Other', () async {
    final (g, dana, _, _) = await seed();
    final e = ((await add(
      g,
      dana,
      500,
      Category.fuel,
      description: 'Gas',
    )) as Ok<Expense>).value;
    expect(e.description, isNull);
    expect(e.title, MessageKey.categoryFuel.text);
    expect((await db.select(db.expenses).getSingle()).description, isNull);
  });

  test('fewer than two Members: needTwoMembers, nothing written', () async {
    final g = await createGroup('Solo');
    final dana = await addMember(g, 'Dana');
    expect(
      await add(g, dana, 3000, Category.hotel),
      const Failure<Expense>(MessageKey.needTwoMembers),
    );
    expect(await list(g), isEmpty);
  });

  test('an Archived group: groupArchived, nothing written', () async {
    final (g, dana, _, _) = await seed();
    await groups.archive(id: g);
    expect(
      await add(g, dana, 3000, Category.hotel),
      const Failure<Expense>(MessageKey.groupArchived),
    );
    expect(await list(g), isEmpty);
  });

  test('a Payer from another Group is a bug', () async {
    final (g, _, _, _) = await seed();
    final (_, other, _, _) = await seed('Budapest');
    await expectLater(
      add(g, other, 3000, Category.hotel),
      throwsA(isA<StateError>()),
    );
    expect(await list(g), isEmpty);
  });

  test('the list is newest first by saveSeq, never by the clock', () async {
    final (g, dana, _, _) = await seed();
    clock.now = 100000000;
    final a = (await add(g, dana, 10, Category.car) as Ok<Expense>).value;
    final b = (await add(g, dana, 20, Category.car) as Ok<Expense>).value;
    final c = (await add(g, dana, 30, Category.car) as Ok<Expense>).value;
    clock.now -= const Duration(days: 1).inMilliseconds;
    final d = (await add(g, dana, 40, Category.car) as Ok<Expense>).value;
    expect([a, b, c, d].map((e) => e.saveSeq), [1, 2, 3, 4]);
    expect((await list(g)).map((e) => e.id), [d.id, c.id, b.id, a.id]);
  });

  test('saveSeq is per Group', () async {
    final (g1, dana, _, _) = await seed();
    final (g2, zoe, _, _) = await seed('Budapest');
    await add(g1, dana, 10, Category.car);
    final e = (await add(g2, zoe, 10, Category.car) as Ok<Expense>).value;
    expect(e.saveSeq, 1);
    expect(await list(g2), [e]);
  });

  test('readLastPayerId is the Payer of the highest saveSeq', () async {
    final (g, dana, yossi, _) = await seed();
    expect(await repo.readLastPayerId(g), isNull);
    await add(g, dana, 10, Category.car);
    await add(g, yossi, 10, Category.car);
    expect(await repo.readLastPayerId(g), yossi.id);
  });

  group('update (FR-13)', () {
    Future<Result<Expense>> edit(
      Expense e, {
      Member? payer,
      int? tenths,
      Category? category,
      String? description,
    }) => repo.update(
      id: e.id,
      payerId: payer?.id ?? e.payerId,
      amount: Tenths(tenths ?? e.amount.value),
      category: category ?? e.category,
      description: description,
    );

    test(
      '₪870 → ₪87 keeps id, saveSeq and createdAt; sets modifiedAt',
      () async {
        final (g, dana, _, _) = await seed();
        final a =
            (await add(g, dana, 8700, Category.foodDrink) as Ok<Expense>).value;
        final b = (await add(g, dana, 100, Category.car) as Ok<Expense>).value;
        clock.now = 5000;
        final edited = (await edit(a, tenths: 870) as Ok<Expense>).value;
        expect(edited.id, a.id);
        expect(edited.groupId, g);
        expect(edited.amount, const Tenths(870));
        expect(edited.saveSeq, a.saveSeq);
        expect(edited.createdAt, 1000);
        expect(edited.modifiedAt, 5000);
        // Same place in the list; the Trip total drops by ₪783.
        final now = await list(g);
        expect(now.map((e) => e.id), [b.id, a.id]);
        expect(now.last, edited);
        expect(tripTotal(now), const Tenths(970));
      },
    );

    test('watchExpense follows edits and is null after a delete', () async {
      final (g, dana, _, _) = await seed();
      final a = (await add(g, dana, 870, Category.car) as Ok<Expense>).value;
      expect(await repo.watchExpense(a.id).first, a);
      final edited = (await edit(a, tenths: 50) as Ok<Expense>).value;
      expect(await repo.watchExpense(a.id).first, edited);
      await repo.delete(id: a.id);
      expect(await repo.watchExpense(a.id).first, isNull);
    });

    for (final (label, tenths) in [('0', 0), ('1,000,001', 10000010)]) {
      test('Amount $label: invalidAmount, nothing written', () async {
        final (g, dana, _, _) = await seed();
        final a = (await add(g, dana, 870, Category.car) as Ok<Expense>).value;
        clock.now = 5000;
        expect(
          await edit(a, tenths: tenths),
          const Failure<Expense>(MessageKey.invalidAmount),
        );
        expect(await list(g), [a]);
      });
    }

    test('Other needs a Description; it is stored trimmed', () async {
      final (g, dana, _, _) = await seed();
      final a = (await add(g, dana, 870, Category.car) as Ok<Expense>).value;
      expect(
        await edit(a, category: Category.other, description: '  '),
        const Failure<Expense>(MessageKey.descriptionRequired),
      );
      final e = (await edit(
        a,
        category: Category.other,
        description: ' Map ',
      ) as Ok<Expense>).value;
      expect(e.description, 'Map');
      // Back to a Category: the Description is dropped.
      final f = (await edit(
        e,
        category: Category.fuel,
        description: 'Map',
      ) as Ok<Expense>).value;
      expect(f.description, isNull);
      expect((await db.select(db.expenses).getSingle()).description, isNull);
    });

    test(
      'Dana → Yossi keeps saveSeq and time; Yossi is the next default',
      () async {
        final (g, dana, yossi, _) = await seed();
        await add(g, dana, 10, Category.car);
        final last =
            (await add(g, dana, 20, Category.car) as Ok<Expense>).value;
        clock.now = 5000;
        final e = (await edit(last, payer: yossi) as Ok<Expense>).value;
        expect(e.payerId, yossi.id);
        expect(e.saveSeq, last.saveSeq);
        expect(e.createdAt, last.createdAt);
        expect(await repo.readLastPayerId(g), yossi.id);
      },
    );

    test('no field changed: nothing written, modifiedAt stays', () async {
      final (g, dana, _, _) = await seed();
      final a = (await add(g, dana, 870, Category.car) as Ok<Expense>).value;
      clock.now = 5000;
      expect(await edit(a), Ok<Expense>(a));
      expect((await db.select(db.expenses).getSingle()).modifiedAt, 1000);
    });

    test('an Archived group: groupArchived, nothing written', () async {
      final (g, dana, _, _) = await seed();
      final a = (await add(g, dana, 870, Category.car) as Ok<Expense>).value;
      await groups.archive(id: g);
      clock.now = 5000;
      expect(
        await edit(a, tenths: 50),
        const Failure<Expense>(MessageKey.groupArchived),
      );
      expect(await list(g), [a]);
    });

    test('an unknown id or a Payer from another Group is a bug', () async {
      final (g, dana, _, _) = await seed();
      final (_, other, _, _) = await seed('Budapest');
      final a = (await add(g, dana, 870, Category.car) as Ok<Expense>).value;
      await expectLater(
        repo.update(
          id: newId(),
          payerId: dana.id,
          amount: const Tenths(10),
          category: Category.car,
        ),
        throwsA(isA<StateError>()),
      );
      await expectLater(edit(a, payer: other), throwsA(isA<StateError>()));
      expect(await list(g), [a]);
    });
  });

  group('delete (FR-14)', () {
    test('an SQL DELETE; the Trip total drops by ₪87', () async {
      final (g, dana, _, _) = await seed();
      final a =
          (await add(g, dana, 870, Category.foodDrink) as Ok<Expense>).value;
      final b = (await add(g, dana, 3000, Category.hotel) as Ok<Expense>).value;
      expect(await repo.delete(id: a.id), isA<Ok<void>>());
      final now = await list(g);
      expect(now, [b]);
      expect(tripTotal(now), const Tenths(3000));
      expect(await db.select(db.expenses).get(), hasLength(1));
    });

    test('a missing id: Ok, nothing written', () async {
      final (g, dana, _, _) = await seed();
      final a = (await add(g, dana, 870, Category.car) as Ok<Expense>).value;
      expect(await repo.delete(id: newId()), isA<Ok<void>>());
      expect(await repo.delete(id: a.id), isA<Ok<void>>());
      expect(await repo.delete(id: a.id), isA<Ok<void>>());
      expect(await list(g), isEmpty);
    });

    test('an Archived group: groupArchived, nothing deleted', () async {
      final (g, dana, _, _) = await seed();
      final a = (await add(g, dana, 870, Category.car) as Ok<Expense>).value;
      await groups.archive(id: g);
      expect(
        await repo.delete(id: a.id),
        const Failure<void>(MessageKey.groupArchived),
      );
      expect(await list(g), [a]);
    });

    test('deleting the last row: the default Payer follows', () async {
      final (g, dana, yossi, _) = await seed();
      await add(g, dana, 10, Category.car);
      final last = (await add(g, yossi, 20, Category.car) as Ok<Expense>).value;
      expect(await repo.readLastPayerId(g), yossi.id);
      await repo.delete(id: last.id);
      expect(await repo.readLastPayerId(g), dana.id);
      // A deleted Payer's Expense no longer blocks removing them.
      expect((await members.removeMember(id: yossi.id)).isOk, isTrue);
    });
  });

  group('watchSnapshot (FR-15)', () {
    /// The snapshot as [Member names, (payer name, tenths) in save order].
    List<List<Object>> view(GroupSnapshot s) {
      final names = {for (final m in s.members) m.id: m.name};
      return [
        [for (final m in s.members) m.name],
        [for (final e in s.expenses) (names[e.payerId]!, e.amount.value)],
      ];
    }

    test('emits at once, then a consistent pair after every change', () async {
      final (g, dana, yossi, noa) = await seed();
      final other = await createGroup('Rome');
      final events = <List<List<Object>>>[];
      final subscription = repo
          .watchSnapshot(g)
          .listen((s) => events.add(view(s)));
      Future<void> settled() => pumpEventQueue();

      await settled();
      expect(events.last, [
        ['Dana', 'Yossi', 'Noa'],
        [],
      ]);

      final expense =
          (await add(g, dana, 3000, Category.hotel) as Ok<Expense>).value;
      await settled();
      expect(events.last, [
        ['Dana', 'Yossi', 'Noa'],
        [('Dana', 3000)],
      ]);

      await add(g, yossi, 500, Category.car);
      await settled();
      expect(events.last[1], [('Dana', 3000), ('Yossi', 500)]);

      await repo.update(
        id: expense.id,
        payerId: dana.id,
        amount: const Tenths(1500),
        category: Category.hotel,
      );
      await settled();
      expect(events.last[1], [('Dana', 1500), ('Yossi', 500)]);

      await members.renameMember(id: dana.id, name: 'Danna');
      await settled();
      expect(events.last, [
        ['Danna', 'Yossi', 'Noa'],
        [('Danna', 1500), ('Yossi', 500)],
      ]);

      await members.removeMember(id: noa.id);
      await settled();
      expect(events.last[0], ['Danna', 'Yossi']);

      await addMember(g, 'Avi');
      await settled();
      expect(events.last[0], ['Danna', 'Yossi', 'Avi']);

      await repo.delete(id: expense.id);
      await settled();
      expect(events.last[1], [('Yossi', 500)]);

      // Another Group's changes never leak in.
      final rome = await addMember(other, 'Eli');
      await addMember(other, 'Gal');
      await add(other, rome, 100, Category.car);
      await settled();
      expect(events.last, [
        ['Danna', 'Yossi', 'Avi'],
        [('Yossi', 500)],
      ]);

      await subscription.cancel();
    });

    test('writes landing during a read are all in the last event', () async {
      final (g, dana, yossi, noa) = await seed();
      final events = <List<List<Object>>>[];
      final subscription = repo
          .watchSnapshot(g)
          .listen((s) => events.add(view(s)));
      // Fired at once, while the first read is still in flight, and
      // without awaiting in between.
      await Future.wait([
        add(g, dana, 100, Category.car),
        add(g, yossi, 200, Category.car),
        add(g, noa, 300, Category.car),
        members.renameMember(id: noa.id, name: 'Noga'),
      ]);
      await pumpEventQueue();
      expect(events.last, [
        ['Dana', 'Yossi', 'Noga'],
        [('Dana', 100), ('Yossi', 200), ('Noga', 300)],
      ]);
      await subscription.cancel();
    });
  });

  group('DriftPayerUsage', () {
    test('a Member who paid is a Payer; one who did not is not', () async {
      final (g, dana, yossi, _) = await seed();
      await add(g, yossi, 10, Category.fuel);
      final usage = DriftPayerUsage(db);
      expect(await usage.isPayer(g, yossi.id), isTrue);
      expect(await usage.isPayer(g, dana.id), isFalse);
    });

    test('removing a Payer is refused; FK RESTRICT backs it up', () async {
      final (g, _, yossi, noa) = await seed();
      await add(g, yossi, 10, Category.fuel);
      expect(
        await members.removeMember(id: yossi.id),
        const Failure<void>(MessageKey.memberIsPayer),
      );
      // Even past the policy, the database refuses the delete.
      await expectLater(
        (db.delete(db.members)..where((m) => m.id.equals(yossi.id))).go(),
        throwsA(anything),
      );
      expect((await members.removeMember(id: noa.id)).isOk, isTrue);
      expect((await members.watchMembers(g).first).map((m) => m.name), [
        'Dana',
        'Yossi',
      ]);
    });
  });

  group('DriftGroupTotals', () {
    test('each Group with Expenses has its Trip total; updates live', () async {
      final (g1, dana, _, _) = await seed();
      final (g2, zoe, _, _) = await seed('Budapest');
      final totals = DriftGroupTotals(db);
      expect(await totals.watchTotals().first, isEmpty);

      await add(g1, dana, 3000, Category.hotel);
      await add(g1, dana, 874, Category.foodDrink);
      await add(g2, zoe, 5, Category.other, description: 'Gum');
      expect(await totals.watchTotals().first, {
        g1: const Tenths(3874),
        g2: const Tenths(5),
      });
    });
  });
}
