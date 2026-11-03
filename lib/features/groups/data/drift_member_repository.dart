import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/policy/member_rules.dart';
import '../../../core/policy/verdict.dart';
import '../../../core/result/result.dart';
import '../../../core/text/names.dart';
import '../../../core/time/clock.dart';
import '../domain/member.dart';
import '../domain/member_repository.dart';

/// The drift [MemberRepository] (AD-3: `groups` writes the `members` table).
final class DriftMemberRepository implements MemberRepository {
  DriftMemberRepository(this._db, this._clock);

  final AppDatabase _db;
  final Clock _clock;

  @override
  Stream<List<Member>> watchMembers(String groupId) =>
      (_db.select(_db.members)
            ..where((m) => m.groupId.equals(groupId))
            ..orderBy([(m) => OrderingTerm.asc(m.memberSeq)]))
          .watch()
          .map((rows) => rows.map(memberFromRow).toList());

  @override
  Future<Result<Member>> addMember({
    required String id,
    required String groupId,
    required String name,
  }) => _db.transaction(() async {
    // Save once (AD-23): a repeated save of the same form writes nothing.
    final existing = await (_db.select(
      _db.members,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    if (existing != null) return Ok(memberFromRow(existing));

    if (isBlankName(name)) return const Failure(MessageKey.nameRequired);
    final normalized = normalizeNameWithin(name, maxMemberNameLength);
    final key = nameKey(normalized);

    final current = await (_db.select(
      _db.members,
    )..where((m) => m.groupId.equals(groupId))).get();

    final verdict = mayAddMember((memberCount: current.length));
    if (verdict case Deny(:final message)) return Failure(message);

    if (current.any((m) => m.nameKey == key)) {
      return const Failure(MessageKey.memberNameTaken);
    }

    final now = _clock.nowUtcMillis();
    final row = MemberRow(
      id: id,
      groupId: groupId,
      name: normalized,
      nameKey: key,
      memberSeq: nextMemberSeq(current.map((m) => m.memberSeq)),
      createdAt: now,
      modifiedAt: now,
    );
    await _db.into(_db.members).insert(row);
    return Ok(memberFromRow(row));
  });
}

/// Maps a drift row to the domain entity (rows never leave `data/`).
Member memberFromRow(MemberRow row) => Member(
  id: row.id,
  groupId: row.groupId,
  name: row.name,
  memberSeq: row.memberSeq,
  createdAt: row.createdAt,
  modifiedAt: row.modifiedAt,
);
