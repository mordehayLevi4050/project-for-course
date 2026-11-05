import '../../../core/result/result.dart';
import 'member.dart';

/// Reads and writes the Members of a Group (FR-2). Implemented in
/// `groups/data`.
///
/// Every write first checks `isGroupMutable` inside its transaction: on an
/// Archived group it writes nothing and returns `Failure(groupArchived)`
/// (FR-6).
abstract interface class MemberRepository {
  /// The Members of [groupId], in add order (`memberSeq`).
  Stream<List<Member>> watchMembers(String groupId);

  /// The Members of [groupId] now, in add order (`memberSeq`). Called inside
  /// a caller's transaction, it reads within that transaction (the Summary
  /// snapshot, FR-15).
  Future<List<Member>> readMembers(String groupId);

  /// Adds a Member named [name] to [groupId] with the form's [id], in one
  /// transaction, with `memberSeq` = MAX + 1.
  ///
  /// Blank → `nameRequired`, 10 Members already → `membersLimit`, taken in
  /// the Group (by `nameKey`) → `memberNameTaken`. When a Member with [id]
  /// already exists, nothing is written and that Member is returned as [Ok].
  Future<Result<Member>> addMember({
    required String id,
    required String groupId,
    required String name,
  });

  /// Renames the Member [id] to [name], in one transaction (FR-3).
  ///
  /// Blank → `nameRequired`; taken by another Member of the same Group (by
  /// `nameKey`) → `memberNameTaken`. The Member's own name is never a
  /// duplicate, so an unchanged or case-only rename succeeds. Updates `name`,
  /// `nameKey` and `modifiedAt`; never `createdAt` or `memberSeq`. An unknown
  /// [id] is a bug and throws a [StateError].
  Future<Result<Member>> renameMember({
    required String id,
    required String name,
  });

  /// Removes the Member [id], in one transaction (FR-4).
  ///
  /// A Member who is the Payer of any Expense (asked through
  /// `PayerUsagePort`) is refused with `memberIsPayer`. A Member that no
  /// longer exists returns [Ok] and writes nothing.
  Future<Result<void>> removeMember({required String id});
}
