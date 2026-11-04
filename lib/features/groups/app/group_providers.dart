import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/money/tenths.dart';
import '../../../core/ports/port_providers.dart';
import '../../../core/result/result.dart';
import '../domain/group.dart';
import '../domain/member.dart';
import 'repository_providers.dart';

part 'group_providers.g.dart';

// --- Reads: repository `.watch()` streams, no caching (AD-5) --------------

/// The group list: the Active group first, then newest first. Archived
/// Groups are not in it.
@riverpod
Stream<List<GroupListItem>> groupList(Ref ref) =>
    ref.watch(groupRepositoryProvider).watchGroups();

/// The Archive view: every Archived group, newest first.
@riverpod
Stream<List<GroupListItem>> archivedGroupList(Ref ref) =>
    ref.watch(groupRepositoryProvider).watchArchivedGroups();

/// The id of the Active group, or `null` when none is set.
@riverpod
Stream<String?> activeGroupId(Ref ref) =>
    ref.watch(groupRepositoryProvider).watchActiveGroupId();

/// The Active group, or `null` when none is set. Used to name it in the
/// Active-group sheet's warning.
@riverpod
Future<Group?> activeGroup(Ref ref) async {
  final id = await ref.watch(activeGroupIdProvider.future);
  if (id == null) return null;
  return ref.watch(groupProvider(id).future);
}

/// One Group, or `null` when it does not exist.
@riverpod
Stream<Group?> group(Ref ref, String id) =>
    ref.watch(groupRepositoryProvider).watchGroup(id);

/// The Members of a Group, in add order.
@riverpod
Stream<List<Member>> members(Ref ref, String groupId) =>
    ref.watch(memberRepositoryProvider).watchMembers(groupId);

// --- Writes: notifier methods, save once (AD-23) ---------------------------

/// Creates a Group. The state is `true` while a save is in flight; calls made
/// meanwhile are ignored and return `null`.
@riverpod
class CreateGroup extends _$CreateGroup {
  @override
  bool build() => false;

  Future<Result<Group>?> submit({
    required String id,
    required String name,
  }) async {
    if (state) return null;
    state = true;
    try {
      return await ref
          .read(groupRepositoryProvider)
          .createGroup(id: id, name: name);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Adds a Member to the Group [groupId]. The state is `true` while a save is
/// in flight; calls made meanwhile are ignored and return `null`.
@riverpod
class AddMember extends _$AddMember {
  @override
  bool build(String groupId) => false;

  Future<Result<Member>?> submit({
    required String id,
    required String name,
  }) async {
    if (state) return null;
    state = true;
    try {
      return await ref
          .read(memberRepositoryProvider)
          .addMember(id: id, groupId: groupId, name: name);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Renames a Group. The state is `true` while a save is in flight; calls made
/// meanwhile are ignored and return `null`.
@riverpod
class RenameGroup extends _$RenameGroup {
  @override
  bool build() => false;

  Future<Result<Group>?> submit({
    required String id,
    required String name,
  }) async {
    if (state) return null;
    state = true;
    try {
      return await ref
          .read(groupRepositoryProvider)
          .renameGroup(id: id, name: name);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Renames a Member. The state is `true` while a save is in flight; calls
/// made meanwhile are ignored and return `null`.
@riverpod
class RenameMember extends _$RenameMember {
  @override
  bool build() => false;

  Future<Result<Member>?> submit({
    required String id,
    required String name,
  }) async {
    if (state) return null;
    state = true;
    try {
      return await ref
          .read(memberRepositoryProvider)
          .renameMember(id: id, name: name);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Removes a Member. The state is `true` while a removal is in flight; calls
/// made meanwhile are ignored and return `null`.
@riverpod
class RemoveMember extends _$RemoveMember {
  @override
  bool build() => false;

  Future<Result<void>?> submit({required String id}) async {
    if (state) return null;
    state = true;
    try {
      return await ref.read(memberRepositoryProvider).removeMember(id: id);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Makes a Group the Active group. The state is `true` while the write is
/// in flight; calls made meanwhile are ignored and return `null`.
@riverpod
class SetActive extends _$SetActive {
  @override
  bool build() => false;

  Future<Result<void>?> submit({required String id}) async {
    if (state) return null;
    state = true;
    try {
      return await ref.read(groupRepositoryProvider).setActive(id: id);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Unsets the Active group. The state is `true` while the write is in
/// flight; calls made meanwhile are ignored and return `null`.
@riverpod
class UnsetActive extends _$UnsetActive {
  @override
  bool build() => false;

  Future<Result<void>?> submit({required String id}) async {
    if (state) return null;
    state = true;
    try {
      return await ref.read(groupRepositoryProvider).unsetActive(id: id);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Archives a Group. The state is `true` while the write is in flight;
/// calls made meanwhile are ignored and return `null`.
@riverpod
class ArchiveGroup extends _$ArchiveGroup {
  @override
  bool build() => false;

  Future<Result<void>?> submit({required String id}) async {
    if (state) return null;
    state = true;
    try {
      return await ref.read(groupRepositoryProvider).archive(id: id);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Restores an Archived group. The state is `true` while the write is in
/// flight; calls made meanwhile are ignored and return `null`.
@riverpod
class RestoreGroup extends _$RestoreGroup {
  @override
  bool build() => false;

  Future<Result<void>?> submit({required String id}) async {
    if (state) return null;
    state = true;
    try {
      return await ref.read(groupRepositoryProvider).restore(id: id);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}

/// Each Group's Trip total for the group cards, from `GroupTotalsPort`
/// (AD-2: `groups` never imports `expenses`). A Group with no Expenses is
/// absent.
@riverpod
Stream<Map<String, Tenths>> groupTotals(Ref ref) =>
    ref.watch(groupTotalsPortProvider).watchTotals();
