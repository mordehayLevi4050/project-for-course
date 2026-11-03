import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/group_repository.dart';
import '../domain/member_repository.dart';

part 'repository_providers.g.dart';

/// Bound by `shell/` (AD-21). Throws until overridden.
@Riverpod(keepAlive: true)
GroupRepository groupRepository(Ref ref) =>
    throw UnimplementedError('groupRepositoryProvider is bound in shell/');

/// Bound by `shell/` (AD-21). Throws until overridden.
@Riverpod(keepAlive: true)
MemberRepository memberRepository(Ref ref) =>
    throw UnimplementedError('memberRepositoryProvider is bound in shell/');
