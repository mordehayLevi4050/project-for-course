import '../../../core/money/tenths.dart';
import '../../../core/result/result.dart';
import 'category.dart';
import 'expense.dart';

/// Reads and writes Expenses (FR-10–FR-12). Implemented in `expenses/data`.
///
/// Every write first checks `isGroupMutable` inside its transaction: on an
/// Archived group it writes nothing and returns `Failure(groupArchived)`
/// (FR-6).
abstract interface class ExpenseRepository {
  /// The Expenses of [groupId], newest first by `saveSeq` (never the clock).
  Stream<List<Expense>> watchExpenses(String groupId);

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
}
