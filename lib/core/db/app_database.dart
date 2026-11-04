import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'app_database.steps.dart';
import 'tables/app_settings.dart';
import 'tables/expenses.dart';
import 'tables/groups.dart';
import 'tables/members.dart';

part 'app_database.g.dart';

/// The app's single database (AD-6, AD-18, AD-20). Every table is declared in
/// `tables/` and registered here. Only `core/db` and feature `data/` import
/// drift.
@DriftDatabase(tables: [Groups, Members, AppSettings, Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database file, opened on a background isolate.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'groupay'));

  /// Test hook: a fresh in-memory database.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  /// Bump on every schema change and run `dart run drift_dev make-migrations`
  /// (AD-18).
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // Story 1.2: the archive column and the Active-group settings row.
      from1To2: (m, schema) async {
        await m.addColumn(schema.groups, schema.groups.archivedAt);
        await m.createTable(schema.appSettings);
      },
      // Story 1.3: Expenses.
      from2To3: (m, schema) async {
        await m.createTable(schema.expenses);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA synchronous = FULL');
    },
  );
}
