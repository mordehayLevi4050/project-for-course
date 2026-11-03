import '../i18n/message_key.dart';
import 'verdict.dart';

/// The most Members a Group can have (FR-2).
const int maxMembersPerGroup = 10;

/// Facts for [mayAddMember]: how many Members the Group has now.
typedef AddMemberFacts = ({int memberCount});

/// FR-2: a Group has at most [maxMembersPerGroup] Members.
Verdict mayAddMember(AddMemberFacts facts) =>
    facts.memberCount >= maxMembersPerGroup
    ? const Deny(MessageKey.membersLimit)
    : const Allow();

/// Facts for [mayRemoveMember]: whether the Member is the Payer of any
/// Expense (answered by `PayerUsagePort`).
typedef RemoveMemberFacts = ({bool isPayer});

/// FR-4: a Member who is the Payer of any Expense cannot be removed.
Verdict mayRemoveMember(RemoveMemberFacts facts) =>
    facts.isPayer ? const Deny(MessageKey.memberIsPayer) : const Allow();

/// AD-9: the `memberSeq` of a new Member is MAX + 1 within its Group, or 1
/// for the first Member. It is assigned once, inside the insert transaction.
int nextMemberSeq(Iterable<int> existingSeqs) => _maxPlusOne(existingSeqs);

/// The `groupSeq` of a new Group is MAX + 1 across all Groups (including
/// archived ones), or 1 for the first Group. It is assigned once, inside the
/// insert transaction, and drives the group list order (newest first).
int nextGroupSeq(Iterable<int> existingSeqs) => _maxPlusOne(existingSeqs);

int _maxPlusOne(Iterable<int> seqs) =>
    seqs.isEmpty ? 1 : seqs.reduce((a, b) => a > b ? a : b) + 1;
