// Schema check for the committed drift snapshots (AD-18).
//
// `dart run drift_dev make-migrations` writes its step-by-step migration test
// only once a second schema version exists. Until then this test validates
// that the live AppDatabase schema matches the committed v1 snapshot
// (drift_schemas/app_database/drift_schema_v1.json). Regenerate the helpers in
// generated/ with make-migrations after every schema change.
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/db/app_database.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  for (final version in GeneratedHelper.versions) {
    test('schema v$version matches its committed snapshot', () async {
      final schema = await verifier.schemaAt(version);
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, version);
      await db.close();
    });
  }

  test('the newest snapshot is the current schemaVersion', () async {
    final db = AppDatabase.memory();
    expect(GeneratedHelper.versions.last, db.schemaVersion);
    await db.close();
  });
}
