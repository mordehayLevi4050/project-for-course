import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/groups.dart';
import 'tables/members.dart';

part 'app_database.g.dart';

/// The app's single database (AD-6, AD-18, AD-20). Every table is declared in
/// `tables/` and registered here. Only `core/db` and feature `data/` import
/// drift.
@DriftDatabase(tables: [Groups, Members])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database file, opened on a background isolate.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'groupay'));

  /// Test hook: a fresh in-memory database.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  /// Bump on every schema change and run `dart run drift_dev make-migrations`
  /// (AD-18).
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA synchronous = FULL');
    },
  );
}
