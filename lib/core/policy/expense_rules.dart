import '../i18n/message_key.dart';
import 'group_rules.dart';
import 'sequence.dart';
import 'verdict.dart';

/// The fewest Members a Group needs before Expenses can be recorded (FR-10).
const int minMembersToRecord = 2;

/// Facts for [mayRecordExpense]: how many Members the Group has now.
typedef RecordExpenseFacts = ({int memberCount});

/// FR-10: an Expense can be recorded only in a Group with at least
/// [minMembersToRecord] Members.
Verdict mayRecordExpense(RecordExpenseFacts facts) =>
    facts.memberCount < minMembersToRecord
    ? const Deny(MessageKey.needTwoMembers)
    : const Allow();

/// FR-13, FR-14, FR-6: an Expense can be edited or deleted only while its
/// Group is not archived (the same rule as [isGroupMutable]). Checked inside
/// the edit and delete transactions.
Verdict mayModifyExpense(GroupStateFacts facts) => isGroupMutable(facts);

/// FR-10: the default Payer of a new Expense.
///
/// [lastPayerId] is the current Payer of the Expense with the highest
/// `saveSeq` in the Group (or `null` when it has no Expenses), and
/// [memberIdsBySeq] are the Group's current Members in `memberSeq` order.
/// The last Payer wins while still a Member; otherwise the earliest-added
/// Member. `null` only when the Group has no Members.
String? defaultPayer({
  required String? lastPayerId,
  required List<String> memberIdsBySeq,
}) {
  if (lastPayerId != null && memberIdsBySeq.contains(lastPayerId)) {
    return lastPayerId;
  }
  return memberIdsBySeq.isEmpty ? null : memberIdsBySeq.first;
}

/// AD-9: the `saveSeq` of a new Expense is MAX + 1 within its Group, or 1
/// for the first Expense. It is assigned once, inside the insert
/// transaction, and never changed by an edit.
int nextSaveSeq(Iterable<int> existingSeqs) => maxPlusOne(existingSeqs);
