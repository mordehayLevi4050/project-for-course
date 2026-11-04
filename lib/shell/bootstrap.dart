import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart';
import '../core/ports/payer_usage_port.dart';
import '../core/time/clock.dart';
import '../features/groups/app/repository_providers.dart';
import '../features/groups/domain/group_repository.dart';
import 'app.dart';
import 'overrides.dart';
import 'payer_usage_stand_in.dart';
import 'router.dart';

/// The launch location (FR-9): the Active group's page, or the group list
/// when no Group is active.
String initialLocationFor(String? activeGroupId) =>
    activeGroupId == null ? '/' : '/group/$activeGroupId';

/// Whether the Group [id] is an Archived group, for the router redirect. An
/// unknown Group is not archived (its page simply shows nothing).
Future<bool> isGroupArchived(GroupRepository groups, String id) async =>
    (await groups.readGroup(id))?.isArchived ?? false;

/// Builds the whole app on [db] (AD-21): binds every provider, reads the
/// Active group before the first frame, and opens the router at its page or
/// at the group list, so the group list never flashes first (FR-9).
///
/// [initialLocation] overrides the launch location (tests only).
Future<Widget> buildGrouPay(
  AppDatabase db, {
  Clock clock = const SystemClock(),
  PayerUsagePort payerUsage = const NoPayerUsage(),
  String? initialLocation,
}) async {
  final container = ProviderContainer(
    overrides: appOverrides(database: db, clock: clock, payerUsage: payerUsage),
  );
  final groups = container.read(groupRepositoryProvider);
  final location =
      initialLocation ?? initialLocationFor(await groups.readActiveGroupId());
  return _OwnedProviderScope(
    container: container,
    child: GrouPayApp(
      router: buildRouter(
        initialLocation: location,
        isArchived: (id) => isGroupArchived(groups, id),
      ),
    ),
  );
}

/// An [UncontrolledProviderScope] that disposes its [container] when it is
/// removed from the tree, as a plain `ProviderScope` would.
class _OwnedProviderScope extends StatefulWidget {
  const _OwnedProviderScope({required this.container, required this.child});

  final ProviderContainer container;
  final Widget child;

  @override
  State<_OwnedProviderScope> createState() => _OwnedProviderScopeState();
}

class _OwnedProviderScopeState extends State<_OwnedProviderScope> {
  @override
  void dispose() {
    widget.container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
    container: widget.container,
    child: widget.child,
  );
}
