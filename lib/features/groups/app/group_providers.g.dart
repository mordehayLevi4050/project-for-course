// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The group list: the Active group first, then newest first. Archived
/// Groups are not in it.

@ProviderFor(groupList)
final groupListProvider = GroupListProvider._();

/// The group list: the Active group first, then newest first. Archived
/// Groups are not in it.

final class GroupListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupListItem>>,
          List<GroupListItem>,
          Stream<List<GroupListItem>>
        >
    with
        $FutureModifier<List<GroupListItem>>,
        $StreamProvider<List<GroupListItem>> {
  /// The group list: the Active group first, then newest first. Archived
  /// Groups are not in it.
  GroupListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupListHash();

  @$internal
  @override
  $StreamProviderElement<List<GroupListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GroupListItem>> create(Ref ref) {
    return groupList(ref);
  }
}

String _$groupListHash() => r'4673a5994301e00c639d8b3931ab2db7dcf38751';

/// The Archive view: every Archived group, newest first.

@ProviderFor(archivedGroupList)
final archivedGroupListProvider = ArchivedGroupListProvider._();

/// The Archive view: every Archived group, newest first.

final class ArchivedGroupListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupListItem>>,
          List<GroupListItem>,
          Stream<List<GroupListItem>>
        >
    with
        $FutureModifier<List<GroupListItem>>,
        $StreamProvider<List<GroupListItem>> {
  /// The Archive view: every Archived group, newest first.
  ArchivedGroupListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archivedGroupListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archivedGroupListHash();

  @$internal
  @override
  $StreamProviderElement<List<GroupListItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GroupListItem>> create(Ref ref) {
    return archivedGroupList(ref);
  }
}

String _$archivedGroupListHash() => r'b61c50931f6689772ca2f002e3078619a21e603a';

/// The id of the Active group, or `null` when none is set.

@ProviderFor(activeGroupId)
final activeGroupIdProvider = ActiveGroupIdProvider._();

/// The id of the Active group, or `null` when none is set.

final class ActiveGroupIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// The id of the Active group, or `null` when none is set.
  ActiveGroupIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGroupIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeGroupIdHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return activeGroupId(ref);
  }
}

String _$activeGroupIdHash() => r'0c5a67651e57ab2d4f3de9ed9e05152a9e738c62';

/// The Active group, or `null` when none is set. Used to name it in the
/// Active-group sheet's warning.

@ProviderFor(activeGroup)
final activeGroupProvider = ActiveGroupProvider._();

/// The Active group, or `null` when none is set. Used to name it in the
/// Active-group sheet's warning.

final class ActiveGroupProvider
    extends $FunctionalProvider<AsyncValue<Group?>, Group?, FutureOr<Group?>>
    with $FutureModifier<Group?>, $FutureProvider<Group?> {
  /// The Active group, or `null` when none is set. Used to name it in the
  /// Active-group sheet's warning.
  ActiveGroupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGroupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeGroupHash();

  @$internal
  @override
  $FutureProviderElement<Group?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Group?> create(Ref ref) {
    return activeGroup(ref);
  }
}

String _$activeGroupHash() => r'4e473b77f56824b3ee83a9506b2beb38ff94417d';

/// One Group, or `null` when it does not exist.

@ProviderFor(group)
final groupProvider = GroupFamily._();

/// One Group, or `null` when it does not exist.

final class GroupProvider
    extends $FunctionalProvider<AsyncValue<Group?>, Group?, Stream<Group?>>
    with $FutureModifier<Group?>, $StreamProvider<Group?> {
  /// One Group, or `null` when it does not exist.
  GroupProvider._({
    required GroupFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupHash();

  @override
  String toString() {
    return r'groupProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Group?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Group?> create(Ref ref) {
    final argument = this.argument as String;
    return group(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupHash() => r'436fb7c37deac8abea20374a7732f8d161202edd';

/// One Group, or `null` when it does not exist.

final class GroupFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Group?>, String> {
  GroupFamily._()
    : super(
        retry: null,
        name: r'groupProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One Group, or `null` when it does not exist.

  GroupProvider call(String id) => GroupProvider._(argument: id, from: this);

  @override
  String toString() => r'groupProvider';
}

/// The Members of a Group, in add order.

@ProviderFor(members)
final membersProvider = MembersFamily._();

/// The Members of a Group, in add order.

final class MembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Member>>,
          List<Member>,
          Stream<List<Member>>
        >
    with $FutureModifier<List<Member>>, $StreamProvider<List<Member>> {
  /// The Members of a Group, in add order.
  MembersProvider._({
    required MembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'membersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$membersHash();

  @override
  String toString() {
    return r'membersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Member>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Member>> create(Ref ref) {
    final argument = this.argument as String;
    return members(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$membersHash() => r'c217339c3c30a6c7a0a7d04be096053698dd7376';

/// The Members of a Group, in add order.

final class MembersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Member>>, String> {
  MembersFamily._()
    : super(
        retry: null,
        name: r'membersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Members of a Group, in add order.

  MembersProvider call(String groupId) =>
      MembersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'membersProvider';
}

/// Creates a Group. The state is `true` while a save is in flight; calls made
/// meanwhile are ignored and return `null`.

@ProviderFor(CreateGroup)
final createGroupProvider = CreateGroupProvider._();

/// Creates a Group. The state is `true` while a save is in flight; calls made
/// meanwhile are ignored and return `null`.
final class CreateGroupProvider extends $NotifierProvider<CreateGroup, bool> {
  /// Creates a Group. The state is `true` while a save is in flight; calls made
  /// meanwhile are ignored and return `null`.
  CreateGroupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createGroupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createGroupHash();

  @$internal
  @override
  CreateGroup create() => CreateGroup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$createGroupHash() => r'9e0f8b241231de1bed546aaf449fdd0499e2de75';

/// Creates a Group. The state is `true` while a save is in flight; calls made
/// meanwhile are ignored and return `null`.

abstract class _$CreateGroup extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Adds a Member to the Group [groupId]. The state is `true` while a save is
/// in flight; calls made meanwhile are ignored and return `null`.

@ProviderFor(AddMember)
final addMemberProvider = AddMemberFamily._();

/// Adds a Member to the Group [groupId]. The state is `true` while a save is
/// in flight; calls made meanwhile are ignored and return `null`.
final class AddMemberProvider extends $NotifierProvider<AddMember, bool> {
  /// Adds a Member to the Group [groupId]. The state is `true` while a save is
  /// in flight; calls made meanwhile are ignored and return `null`.
  AddMemberProvider._({
    required AddMemberFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'addMemberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$addMemberHash();

  @override
  String toString() {
    return r'addMemberProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AddMember create() => AddMember();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AddMemberProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$addMemberHash() => r'185650753400728ee17921e350ae108703f87278';

/// Adds a Member to the Group [groupId]. The state is `true` while a save is
/// in flight; calls made meanwhile are ignored and return `null`.

final class AddMemberFamily extends $Family
    with $ClassFamilyOverride<AddMember, bool, bool, bool, String> {
  AddMemberFamily._()
    : super(
        retry: null,
        name: r'addMemberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Adds a Member to the Group [groupId]. The state is `true` while a save is
  /// in flight; calls made meanwhile are ignored and return `null`.

  AddMemberProvider call(String groupId) =>
      AddMemberProvider._(argument: groupId, from: this);

  @override
  String toString() => r'addMemberProvider';
}

/// Adds a Member to the Group [groupId]. The state is `true` while a save is
/// in flight; calls made meanwhile are ignored and return `null`.

abstract class _$AddMember extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get groupId => _$args;

  bool build(String groupId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Renames a Group. The state is `true` while a save is in flight; calls made
/// meanwhile are ignored and return `null`.

@ProviderFor(RenameGroup)
final renameGroupProvider = RenameGroupProvider._();

/// Renames a Group. The state is `true` while a save is in flight; calls made
/// meanwhile are ignored and return `null`.
final class RenameGroupProvider extends $NotifierProvider<RenameGroup, bool> {
  /// Renames a Group. The state is `true` while a save is in flight; calls made
  /// meanwhile are ignored and return `null`.
  RenameGroupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'renameGroupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$renameGroupHash();

  @$internal
  @override
  RenameGroup create() => RenameGroup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$renameGroupHash() => r'f870f30f04dd95718e61a4d0a04faf8d5a4be80a';

/// Renames a Group. The state is `true` while a save is in flight; calls made
/// meanwhile are ignored and return `null`.

abstract class _$RenameGroup extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Renames a Member. The state is `true` while a save is in flight; calls
/// made meanwhile are ignored and return `null`.

@ProviderFor(RenameMember)
final renameMemberProvider = RenameMemberProvider._();

/// Renames a Member. The state is `true` while a save is in flight; calls
/// made meanwhile are ignored and return `null`.
final class RenameMemberProvider extends $NotifierProvider<RenameMember, bool> {
  /// Renames a Member. The state is `true` while a save is in flight; calls
  /// made meanwhile are ignored and return `null`.
  RenameMemberProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'renameMemberProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$renameMemberHash();

  @$internal
  @override
  RenameMember create() => RenameMember();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$renameMemberHash() => r'b546d2ad6af0d5af8cdeb04bad933e19daf8f360';

/// Renames a Member. The state is `true` while a save is in flight; calls
/// made meanwhile are ignored and return `null`.

abstract class _$RenameMember extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Removes a Member. The state is `true` while a removal is in flight; calls
/// made meanwhile are ignored and return `null`.

@ProviderFor(RemoveMember)
final removeMemberProvider = RemoveMemberProvider._();

/// Removes a Member. The state is `true` while a removal is in flight; calls
/// made meanwhile are ignored and return `null`.
final class RemoveMemberProvider extends $NotifierProvider<RemoveMember, bool> {
  /// Removes a Member. The state is `true` while a removal is in flight; calls
  /// made meanwhile are ignored and return `null`.
  RemoveMemberProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'removeMemberProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$removeMemberHash();

  @$internal
  @override
  RemoveMember create() => RemoveMember();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$removeMemberHash() => r'932b4f4eb59ef6d4fd1e25d9baa0bbdebcf7ff4b';

/// Removes a Member. The state is `true` while a removal is in flight; calls
/// made meanwhile are ignored and return `null`.

abstract class _$RemoveMember extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Makes a Group the Active group. The state is `true` while the write is
/// in flight; calls made meanwhile are ignored and return `null`.

@ProviderFor(SetActive)
final setActiveProvider = SetActiveProvider._();

/// Makes a Group the Active group. The state is `true` while the write is
/// in flight; calls made meanwhile are ignored and return `null`.
final class SetActiveProvider extends $NotifierProvider<SetActive, bool> {
  /// Makes a Group the Active group. The state is `true` while the write is
  /// in flight; calls made meanwhile are ignored and return `null`.
  SetActiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setActiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setActiveHash();

  @$internal
  @override
  SetActive create() => SetActive();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$setActiveHash() => r'6439c3d390d0bdfeac9959da5111463f61f614b1';

/// Makes a Group the Active group. The state is `true` while the write is
/// in flight; calls made meanwhile are ignored and return `null`.

abstract class _$SetActive extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Unsets the Active group. The state is `true` while the write is in
/// flight; calls made meanwhile are ignored and return `null`.

@ProviderFor(UnsetActive)
final unsetActiveProvider = UnsetActiveProvider._();

/// Unsets the Active group. The state is `true` while the write is in
/// flight; calls made meanwhile are ignored and return `null`.
final class UnsetActiveProvider extends $NotifierProvider<UnsetActive, bool> {
  /// Unsets the Active group. The state is `true` while the write is in
  /// flight; calls made meanwhile are ignored and return `null`.
  UnsetActiveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unsetActiveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unsetActiveHash();

  @$internal
  @override
  UnsetActive create() => UnsetActive();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$unsetActiveHash() => r'9463258e8caf0b11e51fbf56730c9312c67bb250';

/// Unsets the Active group. The state is `true` while the write is in
/// flight; calls made meanwhile are ignored and return `null`.

abstract class _$UnsetActive extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Archives a Group. The state is `true` while the write is in flight;
/// calls made meanwhile are ignored and return `null`.

@ProviderFor(ArchiveGroup)
final archiveGroupProvider = ArchiveGroupProvider._();

/// Archives a Group. The state is `true` while the write is in flight;
/// calls made meanwhile are ignored and return `null`.
final class ArchiveGroupProvider extends $NotifierProvider<ArchiveGroup, bool> {
  /// Archives a Group. The state is `true` while the write is in flight;
  /// calls made meanwhile are ignored and return `null`.
  ArchiveGroupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveGroupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveGroupHash();

  @$internal
  @override
  ArchiveGroup create() => ArchiveGroup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$archiveGroupHash() => r'4b5e11434c79623fed04983b289250d8f7262777';

/// Archives a Group. The state is `true` while the write is in flight;
/// calls made meanwhile are ignored and return `null`.

abstract class _$ArchiveGroup extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Restores an Archived group. The state is `true` while the write is in
/// flight; calls made meanwhile are ignored and return `null`.

@ProviderFor(RestoreGroup)
final restoreGroupProvider = RestoreGroupProvider._();

/// Restores an Archived group. The state is `true` while the write is in
/// flight; calls made meanwhile are ignored and return `null`.
final class RestoreGroupProvider extends $NotifierProvider<RestoreGroup, bool> {
  /// Restores an Archived group. The state is `true` while the write is in
  /// flight; calls made meanwhile are ignored and return `null`.
  RestoreGroupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restoreGroupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restoreGroupHash();

  @$internal
  @override
  RestoreGroup create() => RestoreGroup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$restoreGroupHash() => r'6557c1d932427bffde37e96b41d238fd73dd964e';

/// Restores an Archived group. The state is `true` while the write is in
/// flight; calls made meanwhile are ignored and return `null`.

abstract class _$RestoreGroup extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
