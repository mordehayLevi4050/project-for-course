// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:groupay/core/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // Story 1.2 only adds a column and a table, so existing Groups and Members
  // must come through unchanged, with no Group archived.
  test('migration from v1 to v2 does not corrupt data', () async {
    final oldGroupsData = <v1.GroupsData>[
      const v1.GroupsData(
        id: 'g1',
        name: 'Eilat',
        nameKey: 'eilat',
        groupSeq: 1,
        createdAt: 10,
        modifiedAt: 20,
      ),
    ];
    final expectedNewGroupsData = <v2.GroupsData>[
      const v2.GroupsData(
        id: 'g1',
        name: 'Eilat',
        nameKey: 'eilat',
        groupSeq: 1,
        createdAt: 10,
        modifiedAt: 20,
      ),
    ];

    final oldMembersData = <v1.MembersData>[
      const v1.MembersData(
        id: 'm1',
        groupId: 'g1',
        name: 'Dana',
        nameKey: 'dana',
        memberSeq: 1,
        createdAt: 10,
        modifiedAt: 10,
      ),
    ];
    final expectedNewMembersData = <v2.MembersData>[
      const v2.MembersData(
        id: 'm1',
        groupId: 'g1',
        name: 'Dana',
        nameKey: 'dana',
        memberSeq: 1,
        createdAt: 10,
        modifiedAt: 10,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.groups, oldGroupsData);
        batch.insertAll(oldDb.members, oldMembersData);
      },
      validateItems: (newDb) async {
        expect(expectedNewGroupsData, await newDb.select(newDb.groups).get());
        expect(expectedNewMembersData, await newDb.select(newDb.members).get());
        expect(await newDb.select(newDb.appSettings).get(), isEmpty);
      },
    );
  });

  // Story 1.3 only adds the expenses table, so existing Groups, Members and
  // the Active-group row come through unchanged, with no Expenses.
  test('migration from v2 to v3 does not corrupt data', () async {
    const groups = <v2.GroupsData>[
      v2.GroupsData(
        id: 'g1',
        name: 'Eilat',
        nameKey: 'eilat',
        groupSeq: 1,
        createdAt: 10,
        modifiedAt: 20,
        archivedAt: 30,
      ),
      v2.GroupsData(
        id: 'g2',
        name: 'Budapest',
        nameKey: 'budapest',
        groupSeq: 2,
        createdAt: 40,
        modifiedAt: 40,
      ),
    ];
    const members = <v2.MembersData>[
      v2.MembersData(
        id: 'm1',
        groupId: 'g2',
        name: 'Dana',
        nameKey: 'dana',
        memberSeq: 1,
        createdAt: 40,
        modifiedAt: 40,
      ),
    ];
    const settings = <v2.AppSettingsData>[
      v2.AppSettingsData(id: 1, activeGroupId: 'g2'),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.groups, groups);
        batch.insertAll(oldDb.members, members);
        batch.insertAll(oldDb.appSettings, settings);
      },
      validateItems: (newDb) async {
        expect(
          (await newDb.select(newDb.groups).get()).map((g) => g.toJson()),
          groups.map((g) => g.toJson()),
        );
        expect(
          (await newDb.select(newDb.members).get()).map((m) => m.toJson()),
          members.map((m) => m.toJson()),
        );
        expect(
          (await newDb.select(newDb.appSettings).get()).map((s) => s.toJson()),
          settings.map((s) => s.toJson()),
        );
        expect(await newDb.select(newDb.expenses).get(), isEmpty);
      },
    );
  });

  test('the newest snapshot is the current schemaVersion', () async {
    final db = AppDatabase.memory();
    expect(GeneratedHelper.versions.last, db.schemaVersion);
    await db.close();
  });
}
