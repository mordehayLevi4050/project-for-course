import '../../groups/domain/member.dart';
import 'expense.dart';

/// The Members and Expenses of one Group, read together in one transaction
/// (FR-15), so the Transfer calculation never sees a Member list and an
/// Expense list from different moments. Pure Dart (AD-1).
final class GroupSnapshot {
  const GroupSnapshot({required this.members, required this.expenses});

  /// In add order (`memberSeq`).
  final List<Member> members;

  /// In save order (`saveSeq`, oldest first).
  final List<Expense> expenses;

  @override
  String toString() =>
      'GroupSnapshot(${members.length} Members, '
      '${expenses.length} Expenses)';
}
