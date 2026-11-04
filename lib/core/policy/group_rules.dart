import '../i18n/message_key.dart';
import 'verdict.dart';

/// Facts for the Group-state rules: whether the Group is archived.
typedef GroupStateFacts = ({bool isArchived});

/// FR-6: an Archived group is read-only until it is restored. Every write
/// that changes a Group's content (its name, its Members, and later its
/// Expenses) checks this inside its transaction.
Verdict isGroupMutable(GroupStateFacts facts) =>
    facts.isArchived ? const Deny(MessageKey.groupArchived) : const Allow();

/// FR-6: only a Group that is not archived can be archived.
Verdict mayArchive(GroupStateFacts facts) =>
    facts.isArchived ? const Deny(MessageKey.groupArchived) : const Allow();

/// FR-6: only an Archived group can be restored.
Verdict mayRestore(GroupStateFacts facts) =>
    facts.isArchived ? const Allow() : const Deny(MessageKey.groupNotArchived);

/// FR-7, FR-8: an Archived group cannot be the Active group.
Verdict maySetActive(GroupStateFacts facts) =>
    facts.isArchived ? const Deny(MessageKey.groupArchived) : const Allow();
