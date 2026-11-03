import '../../../core/result/result.dart';
import 'group.dart';

/// Reads and writes Groups (FR-1). Implemented in `groups/data`.
abstract interface class GroupRepository {
  /// Every Group with its Member count, newest first by `groupSeq`.
  Stream<List<GroupListItem>> watchGroups();

  /// The Group with [id], or `null` when there is none.
  Stream<Group?> watchGroup(String id);

  /// Creates a Group named [name] with the form's [id], in one transaction.
  ///
  /// The name is normalized and checked: blank → `nameRequired`, taken (by
  /// `nameKey`) → `groupNameTaken`. When a Group with [id] already exists
  /// (a repeated save of the same form), nothing is written and that Group is
  /// returned as [Ok].
  Future<Result<Group>> createGroup({required String id, required String name});

  /// Renames the Group [id] to [name], in one transaction (FR-5).
  ///
  /// Blank → `nameRequired`; taken by another Group (by `nameKey`, including
  /// archived ones) → `groupNameTaken`. The Group's own name is never a
  /// duplicate, so an unchanged or case-only rename succeeds. Updates `name`,
  /// `nameKey` and `modifiedAt`; never `createdAt` or `groupSeq`. An unknown
  /// [id] is a bug and throws a [StateError].
  Future<Result<Group>> renameGroup({required String id, required String name});
}
