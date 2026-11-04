import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/money/tenths.dart';
import '../../../core/policy/expense_rules.dart';
import '../../../core/result/result.dart';
import '../../groups/app/group_providers.dart';
import '../domain/category.dart';
import '../domain/expense.dart';
import '../domain/expense_repository.dart';

part 'expense_providers.g.dart';

/// Bound by `shell/` (AD-21). Throws until overridden.
@Riverpod(keepAlive: true)
ExpenseRepository expenseRepository(Ref ref) =>
    throw UnimplementedError('expenseRepositoryProvider is bound in shell/');

// --- Reads: repository `.watch()` streams, no caching (AD-5) --------------

/// The Expenses of a Group, newest first by `saveSeq`.
@riverpod
Stream<List<Expense>> expenses(Ref ref, String groupId) =>
    ref.watch(expenseRepositoryProvider).watchExpenses(groupId);

/// The default Payer of a new Expense in [groupId] (FR-10): the Payer of the
/// last saved Expense, or the earliest-added Member. Read once when the Add
/// expense screen opens.
@riverpod
Future<String?> defaultPayerId(Ref ref, String groupId) async {
  final members = await ref.watch(membersProvider(groupId).future);
  final lastPayerId = await ref
      .watch(expenseRepositoryProvider)
      .readLastPayerId(groupId);
  return defaultPayer(
    lastPayerId: lastPayerId,
    memberIdsBySeq: [for (final m in members) m.id],
  );
}

// --- Writes: notifier methods, save once (AD-23) ---------------------------

/// Records an Expense. The state is `true` while a save is in flight; calls
/// made meanwhile are ignored and return `null`.
@riverpod
class AddExpense extends _$AddExpense {
  @override
  bool build() => false;

  Future<Result<Expense>?> submit({
    required String id,
    required String groupId,
    required String payerId,
    required Tenths amount,
    required Category category,
    String? description,
  }) async {
    if (state) return null;
    state = true;
    try {
      return await ref
          .read(expenseRepositoryProvider)
          .add(
            id: id,
            groupId: groupId,
            payerId: payerId,
            amount: amount,
            category: category,
            description: description,
          );
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
