import 'package:drift/drift.dart';

import 'groups.dart';

/// App-wide settings: a single row (`id` = 1). Owned and written only by the
/// `groups` feature (AD-3). No other store (such as shared_preferences) holds
/// these values.
@DataClassName('AppSettingsRow')
class AppSettings extends Table {
  /// Always 1: the table holds at most one row.
  IntColumn get id => integer()();

  /// The Active group (FR-7, FR-8), or `null` when none is set. An Archived
  /// group is never active: archiving clears it in the same transaction.
  TextColumn get activeGroupId => text().nullable().references(Groups, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}
