import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:groupay/core/ids/new_id.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/features/expenses/app/expense_providers.dart';
import 'package:groupay/features/expenses/domain/category.dart';
import 'package:groupay/features/expenses/domain/expense.dart';
import 'package:groupay/features/expenses/domain/expense_repository.dart';
import 'package:groupay/features/groups/app/repository_providers.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/member.dart';
import 'package:groupay/shell/overrides.dart';

import '../../../support/fake_clock.dart';

/// An [ExpenseRepository] whose writes complete only when the test says so.
final class _SlowExpenses implements ExpenseRepository {
  final calls = <Completer<Result<Expense>>>[];

  @override
  Future<Result<Expense>> add({
    required String id,
    required String groupId,
    required String payerId,
    required Tenths amount,
    required Category category,
    String? description,
  }) {
    final c = Completer<Result<Expense>>();
    calls.add(c);
    return c.future;
  }

  final edits = <Completer<Result<Expense>>>[];
  final deletes = <Completer<Result<void>>>[];

  @override
  Future<Result<Expense>> update({
    required String id,
    required String payerId,
    required Tenths amount,
    required Category category,
    String? description,
  }) {
    final c = Completer<Result<Expense>>();
    edits.add(c);
    return c.future;
  }

  @override
  Future<Result<void>> delete({required String id}) {
    final c = Completer<Result<void>>();
    deletes.add(c);
    return c.future;
  }

  @override
  Stream<Expense?> watchExpense(String id) => Stream.value(null);

  @override
  Future<String?> readLastPayerId(String groupId) async => null;

  @override
  Stream<List<Expense>> watchExpenses(String groupId) => Stream.value([]);
}

const _expense = Expense(
  id: 'e1',
  groupId: 'g',
  payerId: 'm',
  amount: Tenths(10),
  category: Category.car,
  saveSeq: 1,
  createdAt: 1,
  modifiedAt: 1,
);

void main() {
  test('AddExpense ignores calls while a save is in flight', () async {
    final repo = _SlowExpenses();
    final container = ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(addExpenseProvider, (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(addExpenseProvider.notifier);

    Future<Result<Expense>?> submit() => notifier.submit(
      id: 'e1',
      groupId: 'g',
      payerId: 'm',
      amount: const Tenths(10),
      category: Category.car,
    );

    final first = submit();
    expect(container.read(addExpenseProvider), isTrue);
    expect(await submit(), isNull);
    expect(repo.calls, hasLength(1));

    repo.calls.single.complete(const Ok<Expense>(_expense));
    expect(await first, const Ok<Expense>(_expense));
    expect(container.read(addExpenseProvider), isFalse);
  });

  test('EditExpense ignores calls while a save is in flight', () async {
    final repo = _SlowExpenses();
    final container = ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(editExpenseProvider, (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(editExpenseProvider.notifier);

    Future<Result<Expense>?> submit() => notifier.submit(
      id: 'e1',
      payerId: 'm',
      amount: const Tenths(10),
      category: Category.car,
    );

    final first = submit();
    expect(container.read(editExpenseProvider), isTrue);
    expect(await submit(), isNull);
    expect(repo.edits, hasLength(1));

    repo.edits.single.complete(const Ok<Expense>(_expense));
    expect(await first, const Ok<Expense>(_expense));
    expect(container.read(editExpenseProvider), isFalse);
  });

  test('DeleteExpense ignores calls while a delete is in flight', () async {
    final repo = _SlowExpenses();
    final container = ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(deleteExpenseProvider, (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(deleteExpenseProvider.notifier);

    final first = notifier.submit(id: 'e1');
    expect(container.read(deleteExpenseProvider), isTrue);
    expect(await notifier.submit(id: 'e1'), isNull);
    expect(repo.deletes, hasLength(1));

    repo.deletes.single.complete(const Ok<void>(null));
    expect(await first, isA<Ok<void>>());
    expect(container.read(deleteExpenseProvider), isFalse);
  });

  group('defaultPayerId', () {
    late AppDatabase db;
    late ProviderContainer container;
    late String groupId;
    late Map<String, Member> byName;

    setUp(() async {
      db = AppDatabase.memory();
      container = ProviderContainer(
        overrides: appOverrides(database: db, clock: FakeClock()),
      );
      final group =
          await container
                  .read(groupRepositoryProvider)
                  .createGroup(id: newId(), name: 'Eilat')
              as Ok<Group>;
      groupId = group.value.id;
      byName = {};
      for (final name in ['Motty', 'Dana']) {
        final added =
            await container
                    .read(memberRepositoryProvider)
                    .addMember(id: newId(), groupId: groupId, name: name)
                as Ok<Member>;
        byName[name] = added.value;
      }
    });
    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<String?> read() async {
      final sub = container.listen(defaultPayerIdProvider(groupId), (_, _) {});
      addTearDown(sub.close);
      return container.read(defaultPayerIdProvider(groupId).future);
    }

    Future<void> record(String payer) => container
        .read(expenseRepositoryProvider)
        .add(
          id: newId(),
          groupId: groupId,
          payerId: byName[payer]!.id,
          amount: const Tenths(10),
          category: Category.car,
        );

    test('no Expenses: the earliest-added Member', () async {
      expect(await read(), byName['Motty']!.id);
    });

    test('the Payer of the last saved Expense', () async {
      await record('Motty');
      await record('Dana');
      expect(await read(), byName['Dana']!.id);
    });
  });
}
