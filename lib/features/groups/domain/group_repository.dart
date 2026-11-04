import '../../../core/result/result.dart';
import 'group.dart';

/// Reads and writes Groups (FR-1, FR-5–FR-9) and the Active group. Implemented
/// in `groups/data`.
abstract interface class GroupRepository {
  /// Every Group that is not archived, with its Member count: the Active
  /// group first, then the others newest first by `groupSeq`.
  Stream<List<GroupListItem>> watchGroups();

  /// Every Archived group with its Member count, newest first by `groupSeq`.
  Stream<List<GroupListItem>> watchArchivedGroups();

  /// The Group with [id], or `null` when there is none.
  Stream<Group?> watchGroup(String id);

  /// The Group with [id], read once, or `null` when there is none.
  Future<Group?> readGroup(String id);

  /// The id of the Active group, or `null` when none is set.
  Stream<String?> watchActiveGroupId();

  /// The id of the Active group, read once (before `runApp`, FR-9).
  Future<String?> readActiveGroupId();

  /// Creates a Group named [name] with the form's [id], in one transaction.
  ///
  /// The name is normalized and checked: blank → `nameRequired`, taken (by
  /// `nameKey`, including archived Groups) → `groupNameTaken`. When a Group
  /// with [id] already exists (a repeated save of the same form), nothing is
  /// written and that Group is returned as [Ok].
  Future<Result<Group>> createGroup({required String id, required String name});

  /// Renames the Group [id] to [name], in one transaction (FR-5).
  ///
  /// An Archived group → `groupArchived`. Blank → `nameRequired`; taken by
  /// another Group (by `nameKey`, including archived ones) →
  /// `groupNameTaken`. The Group's own name is never a duplicate, so an
  /// unchanged or case-only rename succeeds. Updates `name`, `nameKey` and
  /// `modifiedAt`; never `createdAt` or `groupSeq`. An unknown [id] is a bug
  /// and throws a [StateError].
  Future<Result<Group>> renameGroup({required String id, required String name});

  /// Makes the Group [id] the only Active group, in one transaction
  /// (FR-7, FR-8). An Archived group → `groupArchived` (`maySetActive`). An
  /// unknown [id] throws a [StateError].
  Future<Result<void>> setActive({required String id});

  /// Unsets the Active group when it is [id], in one transaction (FR-8).
  /// When another Group (or none) is active, nothing is written.
  Future<Result<void>> unsetActive({required String id});

  /// Archives the Group [id], in one transaction (FR-6): sets `archivedAt`
  /// and, when it was the Active group, clears `activeGroupId`. Already
  /// archived → `groupArchived` (`mayArchive`). An unknown [id] throws a
  /// [StateError].
  Future<Result<void>> archive({required String id});

  /// Restores the Archived group [id], in one transaction (FR-6). Its
  /// Members are unchanged and it does not become active. Not archived →
  /// `groupNotArchived` (`mayRestore`). An unknown [id] throws a
  /// [StateError].
  Future<Result<void>> restore({required String id});
}
