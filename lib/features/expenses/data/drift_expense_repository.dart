import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/money/tenths.dart';
import '../../../core/policy/expense_rules.dart';
import '../../../core/policy/group_rules.dart';
import '../../../core/policy/verdict.dart';
import '../../../core/result/result.dart';
import '../../../core/text/description.dart';
import '../../../core/time/clock.dart';
import '../domain/category.dart';
import '../domain/expense.dart';
import '../domain/expense_repository.dart';

/// The drift [ExpenseRepository] (AD-3: `expenses` writes the `expenses`
/// table).
final class DriftExpenseRepository implements ExpenseRepository {
  DriftExpenseRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Stream<List<Expense>> watchExpenses(String groupId) =>
      (_db.select(_db.expenses)
            ..where((e) => e.groupId.equals(groupId))
            ..orderBy([(e) => OrderingTerm.desc(e.saveSeq)]))
          .watch()
          .map((rows) => rows.map(expenseFromRow).toList());

  @override
  Future<String?> readLastPayerId(String groupId) async {
    final row =
        await (_db.select(_db.expenses)
              ..where((e) => e.groupId.equals(groupId))
              ..orderBy([(e) => OrderingTerm.desc(e.saveSeq)])
              ..limit(1))
            .getSingleOrNull();
    return row?.payerId;
  }

  @override
  Future<Result<Expense>> add({
    required String id,
    required String groupId,
    required String payerId,
    required Tenths amount,
    required Category category,
    String? description,
  }) => _db.transaction(() async {
    final mutable = await _checkMutable(groupId);
    if (mutable case Deny(:final message)) return Failure(message);

    // Save once (AD-23): a repeated save of the same form writes nothing.
    final existing = await (_db.select(
      _db.expenses,
    )..where((e) => e.id.equals(id))).getSingleOrNull();
    if (existing != null) return Ok(expenseFromRow(existing));

    final members = await (_db.select(
      _db.members,
    )..where((m) => m.groupId.equals(groupId))).get();
    final verdict = mayRecordExpense((memberCount: members.length));
    if (verdict case Deny(:final message)) return Failure(message);

    if (!members.any((m) => m.id == payerId)) {
      throw StateError('Payer $payerId is not a Member of Group $groupId');
    }

    if (amount <= Tenths.zero || amount > Tenths.max) {
      return const Failure(MessageKey.invalidAmount);
    }

    String? stored;
    if (category.needsDescription) {
      if (description == null || isBlankDescription(description)) {
        return const Failure(MessageKey.descriptionRequired);
      }
      stored = normalizeDescription(description);
    }

    final maxSeq = _db.expenses.saveSeq.max();
    final currentMax =
        await (_db.selectOnly(_db.expenses)
              ..addColumns([maxSeq])
              ..where(_db.expenses.groupId.equals(groupId)))
            .map((r) => r.read(maxSeq))
            .getSingle();

    final now = _clock.nowUtcMillis();
    final row = ExpenseRow(
      id: id,
      groupId: groupId,
      payerId: payerId,
      amount: amount.value,
      category: category.key,
      description: stored,
      saveSeq: nextSaveSeq([?currentMax]),
      createdAt: now,
      modifiedAt: now,
    );
    await _db.into(_db.expenses).insert(row);
    return Ok(expenseFromRow(row));
  });

  /// `isGroupMutable` for [groupId], read inside the caller's transaction
  /// (FR-6: an Archived group's Expenses cannot change). An unknown Group is
  /// a bug and throws a [StateError].
  Future<Verdict> _checkMutable(String groupId) async {
    final group = await (_db.select(
      _db.groups,
    )..where((g) => g.id.equals(groupId))).getSingleOrNull();
    if (group == null) throw StateError('No Group $groupId');
    return isGroupMutable((isArchived: group.archivedAt != null));
  }
}

/// Maps a drift row to the domain entity (rows never leave `data/`).
Expense expenseFromRow(ExpenseRow row) => Expense(
  id: row.id,
  groupId: row.groupId,
  payerId: row.payerId,
  amount: Tenths(row.amount),
  category: Category.fromKey(row.category),
  description: row.description,
  saveSeq: row.saveSeq,
  createdAt: row.createdAt,
  modifiedAt: row.modifiedAt,
);
