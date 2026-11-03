import '../../../core/result/result.dart';
import 'member.dart';

/// Reads and writes the Members of a Group (FR-2). Implemented in
/// `groups/data`.
abstract interface class MemberRepository {
  /// The Members of [groupId], in add order (`memberSeq`).
  Stream<List<Member>> watchMembers(String groupId);

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
}
