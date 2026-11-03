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
}
