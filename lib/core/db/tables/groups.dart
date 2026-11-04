import 'package:drift/drift.dart';

/// A trip Group (FR-1). Owned and written by the `groups` feature (AD-3).
@DataClassName('GroupRow')
class Groups extends Table {
  /// UUID v7, generated when the create form opens (AD-8, AD-23).
  TextColumn get id => text()();

  /// The normalized display name (`core/text` normalizeName).
  TextColumn get name => text()();

  /// The case-folded uniqueness key (`core/text` nameKey). Unique across all
  /// Groups, including archived ones (AD-13).
  TextColumn get nameKey => text().unique()();

  /// MAX + 1 across all Groups, assigned once on insert (`core/policy`
  /// nextGroupSeq). Drives the group list order, newest first; never the
  /// clock or the row id.
  IntColumn get groupSeq => integer().unique()();

  /// UTC epoch millis, set once on insert by the repository (AD-8).
  IntColumn get createdAt => integer()();

  /// UTC epoch millis, set on insert and on every edit (AD-8).
  IntColumn get modifiedAt => integer()();

  /// UTC epoch millis when the Group was archived (FR-6), or `null` while it
  /// is not archived. Set by archive, cleared by restore. Groups are never
  /// deleted.
  IntColumn get archivedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
