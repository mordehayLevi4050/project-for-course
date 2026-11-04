import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/policy/group_rules.dart';
import '../../../core/policy/member_rules.dart';
import '../../../core/policy/verdict.dart';
import '../../../core/result/result.dart';
import '../../../core/text/names.dart';
import '../../../core/time/clock.dart';
import '../domain/group.dart';
import '../domain/group_repository.dart';

/// The id of the single `app_settings` row.
const int _settingsRowId = 1;

/// The drift [GroupRepository] (AD-3: `groups` writes the `groups` and
/// `app_settings` tables).
final class DriftGroupRepository implements GroupRepository {
  DriftGroupRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Stream<List<GroupListItem>> watchGroups() => _watchList(archived: false);

  @override
  Stream<List<GroupListItem>> watchArchivedGroups() =>
      _watchList(archived: true);

  /// The Groups that are (or are not) archived, with their Member count and
  /// whether each is the Active group: the Active group first, then newest
  /// first by `groupSeq`.
  Stream<List<GroupListItem>> _watchList({required bool archived}) {
    final memberCount = _db.members.id.count();
    final isActive = _db.appSettings.id.isNotNull();
    final query =
        _db.select(_db.groups).join([
            leftOuterJoin(
              _db.members,
              _db.members.groupId.equalsExp(_db.groups.id),
            ),
            leftOuterJoin(
              _db.appSettings,
              _db.appSettings.activeGroupId.equalsExp(_db.groups.id),
            ),
          ])
          ..addColumns([memberCount, isActive])
          ..where(
            archived
                ? _db.groups.archivedAt.isNotNull()
                : _db.groups.archivedAt.isNull(),
          )
          ..groupBy([_db.groups.id])
          ..orderBy([
            OrderingTerm.desc(isActive),
            OrderingTerm.desc(_db.groups.groupSeq),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          GroupListItem(
            group: groupFromRow(row.readTable(_db.groups)),
            memberCount: row.read(memberCount) ?? 0,
            isActive: row.read(isActive) ?? false,
          ),
      ],
    );
  }

  @override
  Stream<Group?> watchGroup(String id) =>
      (_db.select(_db.groups)..where((g) => g.id.equals(id)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : groupFromRow(row));

  @override
  Future<Group?> readGroup(String id) async {
    final row = await _find(id);
    return row == null ? null : groupFromRow(row);
  }

  @override
  Stream<String?> watchActiveGroupId() => _db
      .select(_db.appSettings)
      .watchSingleOrNull()
      .map((row) => row?.activeGroupId);

  @override
  Future<String?> readActiveGroupId() async =>
      (await _db.select(_db.appSettings).getSingleOrNull())?.activeGroupId;

  @override
  Future<Result<Group>> createGroup({
    required String id,
    required String name,
  }) => _db.transaction(() async {
    // Save once (AD-23): a repeated save of the same form writes nothing.
    final existing = await _find(id);
    if (existing != null) return Ok(groupFromRow(existing));

    if (isBlankName(name)) return const Failure(MessageKey.nameRequired);
    final normalized = normalizeNameWithin(name, maxGroupNameLength);
    final key = nameKey(normalized);

    // Archived Groups keep their names (FR-6).
    final taken = await (_db.select(
      _db.groups,
    )..where((g) => g.nameKey.equals(key))).getSingleOrNull();
    if (taken != null) return const Failure(MessageKey.groupNameTaken);

    final maxSeq = _db.groups.groupSeq.max();
    final currentMax = await (_db.selectOnly(
      _db.groups,
    )..addColumns([maxSeq])).map((r) => r.read(maxSeq)).getSingle();
    final seq = nextGroupSeq([?currentMax]);

    final now = _clock.nowUtcMillis();
    final row = GroupRow(
      id: id,
      name: normalized,
      nameKey: key,
      groupSeq: seq,
      createdAt: now,
      modifiedAt: now,
    );
    await _db.into(_db.groups).insert(row);
    return Ok(groupFromRow(row));
  });

  @override
  Future<Result<Group>> renameGroup({
    required String id,
    required String name,
  }) => _db.transaction(() async {
    final current = await _require(id, 'rename');

    final mutable = isGroupMutable(_facts(current));
    if (mutable case Deny(:final message)) return Failure(message);

    if (isBlankName(name)) return const Failure(MessageKey.nameRequired);
    final normalized = normalizeNameWithin(name, maxGroupNameLength);
    final key = nameKey(normalized);

    // Checked against every Group except this one (FR-5).
    final taken = await (_db.select(
      _db.groups,
    )..where((g) => g.nameKey.equals(key) & g.id.equals(id).not())).get();
    if (taken.isNotEmpty) return const Failure(MessageKey.groupNameTaken);

    // An unchanged name writes nothing.
    if (normalized == current.name) return Ok(groupFromRow(current));

    final now = _clock.nowUtcMillis();
    await (_db.update(_db.groups)..where((g) => g.id.equals(id))).write(
      GroupsCompanion(
        name: Value(normalized),
        nameKey: Value(key),
        modifiedAt: Value(now),
      ),
    );
    return Ok(
      groupFromRow(
        current.copyWith(name: normalized, nameKey: key, modifiedAt: now),
      ),
    );
  });

  @override
  Future<Result<void>> setActive({required String id}) =>
      _db.transaction(() async {
        final current = await _require(id, 'set active');

        final verdict = maySetActive(_facts(current));
        if (verdict case Deny(:final message)) return Failure(message);

        // One row, one id: at most one Active group.
        await _db
            .into(_db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion(
                id: const Value(_settingsRowId),
                activeGroupId: Value(id),
              ),
            );
        return const Ok<void>(null);
      });

  @override
  Future<Result<void>> unsetActive({required String id}) =>
      _db.transaction(() async {
        await _clearActive(id);
        return const Ok<void>(null);
      });

  @override
  Future<Result<void>> archive({required String id}) =>
      _db.transaction(() async {
        final current = await _require(id, 'archive');

        final verdict = mayArchive(_facts(current));
        if (verdict case Deny(:final message)) return Failure(message);

        await (_db.update(_db.groups)..where((g) => g.id.equals(id))).write(
          GroupsCompanion(archivedAt: Value(_clock.nowUtcMillis())),
        );
        // An Archived group is never active (FR-6, AR17).
        await _clearActive(id);
        return const Ok<void>(null);
      });

  @override
  Future<Result<void>> restore({required String id}) =>
      _db.transaction(() async {
        final current = await _require(id, 'restore');

        final verdict = mayRestore(_facts(current));
        if (verdict case Deny(:final message)) return Failure(message);

        // Nothing else changes: the Group comes back exactly as it was, and
        // it does not become active.
        await (_db.update(_db.groups)..where((g) => g.id.equals(id))).write(
          const GroupsCompanion(archivedAt: Value(null)),
        );
        return const Ok<void>(null);
      });

  Future<GroupRow?> _find(String id) =>
      (_db.select(_db.groups)..where((g) => g.id.equals(id))).getSingleOrNull();

  Future<GroupRow> _require(String id, String action) async {
    final row = await _find(id);
    if (row == null) throw StateError('No Group $id to $action');
    return row;
  }

  /// Clears `activeGroupId` when it is [id].
  Future<void> _clearActive(String id) =>
      (_db.update(_db.appSettings)..where((s) => s.activeGroupId.equals(id)))
          .write(const AppSettingsCompanion(activeGroupId: Value(null)));
}

GroupStateFacts _facts(GroupRow row) => (isArchived: row.archivedAt != null);

/// Maps a drift row to the domain entity (rows never leave `data/`).
Group groupFromRow(GroupRow row) => Group(
  id: row.id,
  name: row.name,
  groupSeq: row.groupSeq,
  createdAt: row.createdAt,
  modifiedAt: row.modifiedAt,
  archivedAt: row.archivedAt,
);
