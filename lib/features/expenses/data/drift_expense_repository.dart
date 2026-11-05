import 'dart:async';

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
import '../../groups/domain/member_repository.dart';
import '../domain/expense_repository.dart';
import '../domain/group_snapshot.dart';

/// The drift [ExpenseRepository] (AD-3: `expenses` writes the `expenses`
/// table).
final class DriftExpenseRepository implements ExpenseRepository {
  DriftExpenseRepository(this._db, this._clock, this._members);

  final AppDatabase _db;
  final Clock _clock;

  /// Reads the Members for [watchSnapshot] (AD-6: the `members` table is
  /// owned by `groups`).
  final MemberRepository _members;

  @override
  Stream<GroupSnapshot> watchSnapshot(String groupId) {
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.members, _db.expenses]),
    );
    StreamSubscription<Set<TableUpdate>>? subscription;
    late final StreamController<GroupSnapshot> controller;
    var reading = false;
    var dirty = false;

    // One read at a time; a change during a read triggers one more read, so
    // the last event always reflects the latest commit.
    Future<void> refresh() async {
      if (reading) {
        dirty = true;
        return;
      }
      reading = true;
      try {
        do {
          dirty = false;
          final snapshot = await _readSnapshot(groupId);
          if (controller.isClosed) return;
          controller.add(snapshot);
        } while (dirty);
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      } finally {
        reading = false;
      }
    }

    controller = StreamController<GroupSnapshot>(
      onListen: () {
        // Listen to changes before the first read, so none is missed.
        subscription = updates.listen((_) => refresh());
        refresh();
      },
      onCancel: () async {
        await subscription?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  Future<GroupSnapshot> _readSnapshot(String groupId) =>
      _db.transaction(() async {
        final members = await _members.readMembers(groupId);
        final rows =
            await (_db.select(_db.expenses)
                  ..where((e) => e.groupId.equals(groupId))
                  ..orderBy([(e) => OrderingTerm.asc(e.saveSeq)]))
                .get();
        return GroupSnapshot(
          members: members,
          expenses: rows.map(expenseFromRow).toList(),
        );
      });

  @override
  Stream<List<Expense>> watchExpenses(String groupId) =>
      (_db.select(_db.expenses)
            ..where((e) => e.groupId.equals(groupId))
            ..orderBy([(e) => OrderingTerm.desc(e.saveSeq)]))
          .watch()
          .map((rows) => rows.map(expenseFromRow).toList());

  @override
  Stream<Expense?> watchExpense(String id) =>
      (_db.select(_db.expenses)..where((e) => e.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : expenseFromRow(row));

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

    final checked = _validate(
      groupId: groupId,
      members: members,
      payerId: payerId,
      amount: amount,
      category: category,
      description: description,
    );
    if (checked case Failure(:final message)) return Failure(message);
    final stored = (checked as Ok<String?>).value;

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

  @override
  Future<Result<Expense>> update({
    required String id,
    required String payerId,
    required Tenths amount,
    required Category category,
    String? description,
  }) => _db.transaction(() async {
    final current = await _readRow(id);
    if (current == null) throw StateError('No Expense $id');
    final groupId = current.groupId;
    final modifiable = mayModifyExpense(await _groupState(groupId));
    if (modifiable case Deny(:final message)) return Failure(message);

    final members = await (_db.select(
      _db.members,
    )..where((m) => m.groupId.equals(groupId))).get();
    final checked = _validate(
      groupId: groupId,
      members: members,
      payerId: payerId,
      amount: amount,
      category: category,
      description: description,
    );
    if (checked case Failure(:final message)) return Failure(message);
    final stored = (checked as Ok<String?>).value;

    // Saving with no field changed writes nothing (modifiedAt stays).
    if (current.payerId == payerId &&
        current.amount == amount.value &&
        current.category == category.key &&
        current.description == stored) {
      return Ok(expenseFromRow(current));
    }

    final row = current.copyWith(
      payerId: payerId,
      amount: amount.value,
      category: category.key,
      description: Value(stored),
      modifiedAt: _clock.nowUtcMillis(),
    );
    await (_db.update(_db.expenses)..where((e) => e.id.equals(id))).write(
      ExpensesCompanion(
        payerId: Value(row.payerId),
        amount: Value(row.amount),
        category: Value(row.category),
        description: Value(row.description),
        modifiedAt: Value(row.modifiedAt),
      ),
    );
    return Ok(expenseFromRow(row));
  });

  @override
  Future<Result<void>> delete({required String id}) =>
      _db.transaction(() async {
        final current = await _readRow(id);
        if (current == null) return const Ok<void>(null);
        final modifiable = mayModifyExpense(await _groupState(current.groupId));
        if (modifiable case Deny(:final message)) return Failure(message);
        await (_db.delete(_db.expenses)..where((e) => e.id.equals(id))).go();
        return const Ok<void>(null);
      });

  Future<ExpenseRow?> _readRow(String id) => (_db.select(
    _db.expenses,
  )..where((e) => e.id.equals(id))).getSingleOrNull();

  /// The add and edit checks after the Group-state rule (FR-11): the Payer
  /// is a current Member (a bug otherwise: [StateError]), the Amount is in
  /// bounds, and *Other* has a Description. Returns the Description to
  /// store: trimmed for *Other*, `null` for any other Category.
  Result<String?> _validate({
    required String groupId,
    required List<MemberRow> members,
    required String payerId,
    required Tenths amount,
    required Category category,
    String? description,
  }) {
    if (!members.any((m) => m.id == payerId)) {
      throw StateError('Payer $payerId is not a Member of Group $groupId');
    }
    if (amount <= Tenths.zero || amount > Tenths.max) {
      return const Failure(MessageKey.invalidAmount);
    }
    if (!category.needsDescription) return const Ok<String?>(null);
    if (description == null || isBlankDescription(description)) {
      return const Failure(MessageKey.descriptionRequired);
    }
    return Ok(normalizeDescription(description));
  }

  /// The Group-state facts of [groupId], read inside the caller's
  /// transaction. An unknown Group is a bug and throws a [StateError].
  Future<GroupStateFacts> _groupState(String groupId) async {
    final group = await (_db.select(
      _db.groups,
    )..where((g) => g.id.equals(groupId))).getSingleOrNull();
    if (group == null) throw StateError('No Group $groupId');
    return (isArchived: group.archivedAt != null);
  }

  /// `isGroupMutable` for [groupId], read inside the caller's transaction
  /// (FR-6: an Archived group's Expenses cannot change). An unknown Group is
  /// a bug and throws a [StateError].
  Future<Verdict> _checkMutable(String groupId) async =>
      isGroupMutable(await _groupState(groupId));
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
