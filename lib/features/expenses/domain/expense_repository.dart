import '../../../core/money/tenths.dart';
import '../../../core/result/result.dart';
import 'category.dart';
import 'expense.dart';
import 'group_snapshot.dart';

/// Reads and writes Expenses (FR-10–FR-12). Implemented in `expenses/data`.
///
/// Every write first checks `isGroupMutable` inside its transaction: on an
/// Archived group it writes nothing and returns `Failure(groupArchived)`
/// (FR-6).
abstract interface class ExpenseRepository {
  /// The Expenses of [groupId], newest first by `saveSeq` (never the clock).
  Stream<List<Expense>> watchExpenses(String groupId);

  /// The Members (add order) and Expenses (save order, oldest first) of
  /// [groupId], read together in one transaction (FR-15). Emits once at
  /// once, then again after every change to the `members` or `expenses`
  /// table.
  Stream<GroupSnapshot> watchSnapshot(String groupId);

  /// The Expense [id], or `null` when there is none (or it was deleted).
  Stream<Expense?> watchExpense(String id);

  /// The Payer of the Expense with the highest `saveSeq` in [groupId], or
  /// `null` when the Group has no Expenses (for `defaultPayer`).
  Future<String?> readLastPayerId(String groupId);

  /// Records an Expense with the form's [id], in one transaction (FR-10,
  /// FR-11), with `saveSeq` = MAX + 1 and `createdAt` = `modifiedAt` = now.
  ///
  /// Archived → `groupArchived`; fewer than two Members → `needTwoMembers`
  /// (`mayRecordExpense`); an Amount ≤ 0 or above ₪1,000,000 →
  /// `invalidAmount`; *Other* with a blank [description] →
  /// `descriptionRequired`. The Description is stored (trimmed) only for
  /// *Other*. When an Expense with [id] already exists (a repeated save of
  /// the same form), nothing is written and that Expense is returned as
  /// [Ok]. A [payerId] that is not a current Member of the Group, or an
  /// unknown Group, is a bug and throws a [StateError].
  Future<Result<Expense>> add({
    required String id,
    required String groupId,
    required String payerId,
    required Tenths amount,
    required Category category,
    String? description,
  });

  /// Edits the Expense [id] in one transaction (FR-13): Archived →
  /// `groupArchived` (`mayModifyExpense`), then the same checks as [add]
  /// (Amount bounds, the *Other* Description, the Payer is a current Member).
  ///
  /// `id`, `groupId`, `saveSeq` and `createdAt` are kept; `modifiedAt` is set
  /// to now. When nothing differs from the stored Expense, nothing is
  /// written and it is returned as [Ok]. An unknown [id], or a [payerId] that
  /// is not a current Member, is a bug and throws a [StateError].
  Future<Result<Expense>> update({
    required String id,
    required String payerId,
    required Tenths amount,
    required Category category,
    String? description,
  });

  /// Deletes the Expense [id] with an SQL `DELETE`, in one transaction
  /// (FR-14). Archived → `groupArchived` (`mayModifyExpense`) and nothing is
  /// deleted. A missing [id] (already deleted) writes nothing and is [Ok].
  Future<Result<void>> delete({required String id});
}
