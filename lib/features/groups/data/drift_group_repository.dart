import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/policy/member_rules.dart';
import '../../../core/result/result.dart';
import '../../../core/text/names.dart';
import '../../../core/time/clock.dart';
import '../domain/group.dart';
import '../domain/group_repository.dart';

/// The drift [GroupRepository] (AD-3: `groups` writes the `groups` table).
final class DriftGroupRepository implements GroupRepository {
  DriftGroupRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Stream<List<GroupListItem>> watchGroups() {
    final memberCount = _db.members.id.count();
    final query =
        _db.select(_db.groups).join([
            leftOuterJoin(
              _db.members,
              _db.members.groupId.equalsExp(_db.groups.id),
            ),
          ])
          ..addColumns([memberCount])
          ..groupBy([_db.groups.id])
          ..orderBy([OrderingTerm.desc(_db.groups.groupSeq)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          GroupListItem(
            group: groupFromRow(row.readTable(_db.groups)),
            memberCount: row.read(memberCount) ?? 0,
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
  Future<Result<Group>> createGroup({
    required String id,
    required String name,
  }) => _db.transaction(() async {
    // Save once (AD-23): a repeated save of the same form writes nothing.
    final existing = await (_db.select(
      _db.groups,
    )..where((g) => g.id.equals(id))).getSingleOrNull();
    if (existing != null) return Ok(groupFromRow(existing));

    if (isBlankName(name)) return const Failure(MessageKey.nameRequired);
    final normalized = normalizeNameWithin(name, maxGroupNameLength);
    final key = nameKey(normalized);

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
}

/// Maps a drift row to the domain entity (rows never leave `data/`).
Group groupFromRow(GroupRow row) => Group(
  id: row.id,
  name: row.name,
  groupSeq: row.groupSeq,
  createdAt: row.createdAt,
  modifiedAt: row.modifiedAt,
);
