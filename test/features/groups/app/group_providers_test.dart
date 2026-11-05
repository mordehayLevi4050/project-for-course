import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/result/result.dart';
import 'package:groupay/features/groups/app/group_providers.dart';
import 'package:groupay/features/groups/app/repository_providers.dart';
import 'package:groupay/features/groups/domain/group.dart';
import 'package:groupay/features/groups/domain/group_repository.dart';
import 'package:groupay/features/groups/domain/member.dart';
import 'package:groupay/features/groups/domain/member_repository.dart';

/// Repositories whose writes complete only when the test says so.
final class _SlowRepos implements GroupRepository, MemberRepository {
  final groupCalls = <Completer<Result<Group>>>[];
  final memberCalls = <Completer<Result<Member>>>[];

  @override
  Future<Result<Group>> createGroup({
    required String id,
    required String name,
  }) {
    final c = Completer<Result<Group>>();
    groupCalls.add(c);
    return c.future;
  }

  @override
  Future<Result<Member>> addMember({
    required String id,
    required String groupId,
    required String name,
  }) {
    final c = Completer<Result<Member>>();
    memberCalls.add(c);
    return c.future;
  }

  final renameGroupCalls = <Completer<Result<Group>>>[];
  final renameMemberCalls = <Completer<Result<Member>>>[];
  final removeCalls = <Completer<Result<void>>>[];

  @override
  Future<Result<Group>> renameGroup({
    required String id,
    required String name,
  }) {
    final c = Completer<Result<Group>>();
    renameGroupCalls.add(c);
    return c.future;
  }

  @override
  Future<Result<Member>> renameMember({
    required String id,
    required String name,
  }) {
    final c = Completer<Result<Member>>();
    renameMemberCalls.add(c);
    return c.future;
  }

  @override
  Future<Result<void>> removeMember({required String id}) {
    final c = Completer<Result<void>>();
    removeCalls.add(c);
    return c.future;
  }

  @override
  Stream<List<GroupListItem>> watchGroups() => const Stream.empty();

  @override
  Stream<Group?> watchGroup(String id) => const Stream.empty();

  @override
  Stream<List<GroupListItem>> watchArchivedGroups() => const Stream.empty();

  @override
  Stream<String?> watchActiveGroupId() => const Stream.empty();

  @override
  Future<String?> readActiveGroupId() async => null;

  @override
  Future<Group?> readGroup(String id) async => null;

  final setActiveCalls = <Completer<Result<void>>>[];
  final unsetActiveCalls = <Completer<Result<void>>>[];
  final archiveCalls = <Completer<Result<void>>>[];
  final restoreCalls = <Completer<Result<void>>>[];

  Future<Result<void>> _pending(List<Completer<Result<void>>> calls) {
    final c = Completer<Result<void>>();
    calls.add(c);
    return c.future;
  }

  @override
  Future<Result<void>> setActive({required String id}) =>
      _pending(setActiveCalls);

  @override
  Future<Result<void>> unsetActive({required String id}) =>
      _pending(unsetActiveCalls);

  @override
  Future<Result<void>> archive({required String id}) => _pending(archiveCalls);

  @override
  Future<Result<void>> restore({required String id}) => _pending(restoreCalls);

  @override
  Stream<List<Member>> watchMembers(String groupId) => const Stream.empty();

  @override
  Future<List<Member>> readMembers(String groupId) async => const [];
}

void main() {
  const group = Group(
    id: 'g',
    name: 'Eilat',
    groupSeq: 1,
    createdAt: 1,
    modifiedAt: 1,
  );
  const member = Member(
    id: 'm',
    groupId: 'g',
    name: 'Dana',
    memberSeq: 1,
    createdAt: 1,
    modifiedAt: 1,
  );

  late _SlowRepos repos;
  late ProviderContainer container;

  setUp(() {
    repos = _SlowRepos();
    container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(repos),
        memberRepositoryProvider.overrideWithValue(repos),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('repository providers throw until shell binds them', () {
    final bare = ProviderContainer();
    addTearDown(bare.dispose);
    expect(() => bare.read(groupRepositoryProvider), throwsA(anything));
    expect(() => bare.read(memberRepositoryProvider), throwsA(anything));
  });

  test('CreateGroup ignores calls while a save is in flight', () async {
    final sub = container.listen(createGroupProvider, (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(createGroupProvider.notifier);

    final first = notifier.submit(id: 'g', name: 'Eilat');
    expect(container.read(createGroupProvider), isTrue);
    expect(await notifier.submit(id: 'g', name: 'Eilat'), isNull);
    expect(repos.groupCalls, hasLength(1));

    repos.groupCalls.single.complete(const Ok(group));
    expect(await first, const Ok(group));
    expect(container.read(createGroupProvider), isFalse);
  });

  test('AddMember ignores calls while a save is in flight', () async {
    final sub = container.listen(addMemberProvider('g'), (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(addMemberProvider('g').notifier);

    final first = notifier.submit(id: 'm', name: 'Dana');
    expect(await notifier.submit(id: 'm', name: 'Dana'), isNull);
    expect(repos.memberCalls, hasLength(1));

    repos.memberCalls.single.complete(const Ok(member));
    expect(await first, const Ok(member));
    expect(container.read(addMemberProvider('g')), isFalse);

    // The next add goes through.
    unawaited(notifier.submit(id: 'm2', name: 'Yossi'));
    expect(repos.memberCalls, hasLength(2));
  });

  test('RenameGroup ignores calls while a save is in flight', () async {
    final sub = container.listen(renameGroupProvider, (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(renameGroupProvider.notifier);

    final first = notifier.submit(id: 'g', name: 'Eilat 2026');
    expect(container.read(renameGroupProvider), isTrue);
    expect(await notifier.submit(id: 'g', name: 'Eilat 2026'), isNull);
    expect(repos.renameGroupCalls, hasLength(1));

    repos.renameGroupCalls.single.complete(const Ok(group));
    expect(await first, const Ok(group));
    expect(container.read(renameGroupProvider), isFalse);
  });

  test('RenameMember ignores calls while a save is in flight', () async {
    final sub = container.listen(renameMemberProvider, (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(renameMemberProvider.notifier);

    final first = notifier.submit(id: 'm', name: 'Danna');
    expect(await notifier.submit(id: 'm', name: 'Danna'), isNull);
    expect(repos.renameMemberCalls, hasLength(1));

    repos.renameMemberCalls.single.complete(const Ok(member));
    expect(await first, const Ok(member));
    expect(container.read(renameMemberProvider), isFalse);
  });

  test('RemoveMember ignores calls while a removal is in flight', () async {
    final sub = container.listen(removeMemberProvider, (_, _) {});
    addTearDown(sub.close);
    final notifier = container.read(removeMemberProvider.notifier);

    final first = notifier.submit(id: 'm');
    expect(await notifier.submit(id: 'm'), isNull);
    expect(repos.removeCalls, hasLength(1));

    repos.removeCalls.single.complete(const Ok<void>(null));
    expect((await first)!.isOk, isTrue);
    expect(container.read(removeMemberProvider), isFalse);
  });

  /// The in-flight guard shared by the Active-group and archive notifiers:
  /// while the first write is pending the state is `true`, a second call
  /// returns `null` and the repository is called once; afterwards the state
  /// is `false`.
  Future<void> expectGuarded({
    required ProviderListenable<bool> state,
    required Future<Result<void>?> Function() submit,
    required List<Completer<Result<void>>> calls,
  }) async {
    final sub = container.listen(state, (_, _) {});
    addTearDown(sub.close);

    final first = submit();
    expect(container.read(state), isTrue);
    expect(await submit(), isNull);
    expect(calls, hasLength(1));

    calls.single.complete(const Ok<void>(null));
    expect((await first)!.isOk, isTrue);
    expect(container.read(state), isFalse);
  }

  test('SetActive ignores calls while a write is in flight', () async {
    await expectGuarded(
      state: setActiveProvider,
      submit: () => container.read(setActiveProvider.notifier).submit(id: 'g'),
      calls: repos.setActiveCalls,
    );
  });

  test('UnsetActive ignores calls while a write is in flight', () async {
    await expectGuarded(
      state: unsetActiveProvider,
      submit: () =>
          container.read(unsetActiveProvider.notifier).submit(id: 'g'),
      calls: repos.unsetActiveCalls,
    );
  });

  test('ArchiveGroup ignores calls while a write is in flight', () async {
    await expectGuarded(
      state: archiveGroupProvider,
      submit: () =>
          container.read(archiveGroupProvider.notifier).submit(id: 'g'),
      calls: repos.archiveCalls,
    );
  });

  test('RestoreGroup ignores calls while a write is in flight', () async {
    await expectGuarded(
      state: restoreGroupProvider,
      submit: () =>
          container.read(restoreGroupProvider.notifier).submit(id: 'g'),
      calls: repos.restoreCalls,
    );
  });
}
