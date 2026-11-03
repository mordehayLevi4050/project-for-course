import 'package:drift/drift.dart';

import 'groups.dart';

/// A Member of a Group (FR-2). Owned and written by the `groups` feature
/// (AD-3). Removal is a hard delete (AD-10).
@DataClassName('MemberRow')
class Members extends Table {
  /// UUID v7, generated when the add form opens (AD-8, AD-23).
  TextColumn get id => text()();

  TextColumn get groupId => text().references(Groups, #id)();

  /// The normalized display name (`core/text` normalizeName).
  TextColumn get name => text()();

  /// The case-folded uniqueness key (`core/text` nameKey), unique per Group.
  TextColumn get nameKey => text()();

  /// MAX + 1 within the Group, assigned once (AD-9). Drives the earliest
  /// Member, payer-picker order and avatar color.
  IntColumn get memberSeq => integer()();

  /// UTC epoch millis, set once on insert by the repository (AD-8).
  IntColumn get createdAt => integer()();

  /// UTC epoch millis, set on insert and on every edit (AD-8).
  IntColumn get modifiedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {groupId, nameKey},
    {groupId, memberSeq},
    // Target of the composite FK expenses(groupId, payerId) (AD-18).
    {groupId, id},
  ];
}
