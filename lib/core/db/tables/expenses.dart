import 'package:drift/drift.dart';

import 'groups.dart';

/// An Expense of a Group (FR-10). Owned and written only by the `expenses`
/// feature (AD-3). Removal is a hard delete (AD-10). No participant list is
/// stored: every Expense is split among all current Members (AR16).
@DataClassName('ExpenseRow')
class Expenses extends Table {
  /// UUID v7, generated when the add form opens (AD-8, AD-23).
  TextColumn get id => text()();

  TextColumn get groupId => text().references(Groups, #id)();

  /// The Payer: a Member of the same Group. The composite FK below
  /// references `members(group_id, id)` with `ON DELETE RESTRICT`, which
  /// backs up the FR-4 policy.
  TextColumn get payerId => text()();

  /// The Amount in ₪0.10 units (`core/money` Tenths).
  IntColumn get amount => integer()();

  /// The stable key of the Category enum. A key is never renamed and never
  /// holds localized text.
  TextColumn get category => text()();

  /// Stored only for the *Other* Category (trimmed), otherwise `null`.
  TextColumn get description => text().nullable()();

  /// MAX + 1 within the Group, assigned once inside the insert transaction
  /// (AD-9). Drives the list order, the default Payer and the Leftover
  /// tie-break; never the clock.
  IntColumn get saveSeq => integer()();

  /// UTC epoch millis of the first save, set once by the repository (AD-8).
  IntColumn get createdAt => integer()();

  /// UTC epoch millis, set on insert and on every edit (AD-8).
  IntColumn get modifiedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {groupId, saveSeq},
  ];

  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (group_id, payer_id) REFERENCES members (group_id, id) '
        'ON DELETE RESTRICT',
  ];
}
