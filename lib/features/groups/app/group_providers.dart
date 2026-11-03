import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/result/result.dart';
import '../domain/group.dart';
import '../domain/member.dart';
import 'repository_providers.dart';

part 'group_providers.g.dart';

// --- Reads: repository `.watch()` streams, no caching (AD-5) --------------

/// The group list, newest first.
@riverpod
Stream<List<GroupListItem>> groupList(Ref ref) =>
    ref.watch(groupRepositoryProvider).watchGroups();

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
