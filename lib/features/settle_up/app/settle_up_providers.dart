import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/policy/expense_rules.dart';
import '../../expenses/app/expense_providers.dart';
import '../../expenses/domain/group_snapshot.dart';
import '../domain/settlement.dart';

part 'settle_up_providers.g.dart';

/// What the Summary shows: one [snapshot] of the Group's Members and
/// Expenses, and the [settlement] computed from that same snapshot, or
/// `null` while `maySummarize` denies it (fewer than two Members).
final class SummaryView {
  const SummaryView({required this.snapshot, required this.settlement});

  final GroupSnapshot snapshot;
  final Settlement? settlement;
}

/// The Summary of [groupId] (FR-15, FR-16). It only reads: each snapshot
/// from `watchSnapshot` is checked with `maySummarize` and settled by the
/// pure calculation, again after every change to Members or Expenses.
@riverpod
Stream<SummaryView> settlement(Ref ref, String groupId) => ref
    .watch(expenseRepositoryProvider)
    .watchSnapshot(groupId)
    .map(
      (snapshot) => SummaryView(
        snapshot: snapshot,
        settlement:
            maySummarize((memberCount: snapshot.members.length)).isAllowed
            ? settle(snapshot.members, snapshot.expenses)
            : null,
      ),
    );
