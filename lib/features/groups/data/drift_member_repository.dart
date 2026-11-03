import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/policy/member_rules.dart';
import '../../../core/policy/verdict.dart';
import '../../../core/ports/payer_usage_port.dart';
import '../../../core/result/result.dart';
import '../../../core/text/names.dart';
import '../../../core/time/clock.dart';
import '../domain/member.dart';
import '../domain/member_repository.dart';

/// The drift [MemberRepository] (AD-3: `groups` writes the `members` table).
final class DriftMemberRepository implements MemberRepository {
  DriftMemberRepository(this._db, this._clock, this._payerUsage);

  final AppDatabase _db;
  final Clock _clock;

  /// Answers FR-4's "is this Member a Payer?" (AD-2: that fact is owned by
  /// `expenses`).
  final PayerUsagePort _payerUsage;

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

  @override
  Future<Result<Member>> renameMember({
    required String id,
    required String name,
  }) => _db.transaction(() async {
    final current = await (_db.select(
      _db.members,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
    if (current == null) throw StateError('No Member $id to rename');

    if (isBlankName(name)) return const Failure(MessageKey.nameRequired);
    final normalized = normalizeNameWithin(name, maxMemberNameLength);
    final key = nameKey(normalized);

    // Checked against the other Members of the same Group only (FR-3).
    final taken =
        await (_db.select(_db.members)..where(
              (m) =>
                  m.groupId.equals(current.groupId) &
                  m.nameKey.equals(key) &
                  m.id.equals(id).not(),
            ))
            .get();
    if (taken.isNotEmpty) return const Failure(MessageKey.memberNameTaken);

    // An unchanged name writes nothing.
    if (normalized == current.name) return Ok(memberFromRow(current));

    final now = _clock.nowUtcMillis();
    await (_db.update(_db.members)..where((m) => m.id.equals(id))).write(
      MembersCompanion(
        name: Value(normalized),
        nameKey: Value(key),
        modifiedAt: Value(now),
      ),
    );
    return Ok(
      memberFromRow(
        current.copyWith(name: normalized, nameKey: key, modifiedAt: now),
      ),
    );
  });

  @override
  Future<Result<void>> removeMember({required String id}) =>
      _db.transaction(() async {
        final current = await (_db.select(
          _db.members,
        )..where((m) => m.id.equals(id))).getSingleOrNull();
        // Already gone: nothing to write.
        if (current == null) return const Ok<void>(null);

        final isPayer = await _payerUsage.isPayer(current.groupId, id);
        final verdict = mayRemoveMember((isPayer: isPayer));
        if (verdict case Deny(:final message)) return Failure(message);

        await (_db.delete(_db.members)..where((m) => m.id.equals(id))).go();
        return const Ok<void>(null);
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
