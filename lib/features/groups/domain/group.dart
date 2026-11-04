/// A trip Group (glossary: Group). Pure Dart (AD-1).
final class Group {
  const Group({
    required this.id,
    required this.name,
    required this.groupSeq,
    required this.createdAt,
    required this.modifiedAt,
    this.archivedAt,
  });

  /// UUID v7.
  final String id;

  /// The normalized display name.
  final String name;

  /// Creation order across all Groups (MAX + 1, set once).
  final int groupSeq;

  /// UTC epoch millis, set once on insert.
  final int createdAt;

  /// UTC epoch millis, set on insert and on every edit.
  final int modifiedAt;

  /// UTC epoch millis when the Group was archived, or `null` (FR-6).
  final int? archivedAt;

  /// Whether the Group is an Archived group (read-only until restored).
  bool get isArchived => archivedAt != null;

  @override
  bool operator ==(Object other) =>
      other is Group &&
      other.id == id &&
      other.name == name &&
      other.groupSeq == groupSeq &&
      other.createdAt == createdAt &&
      other.modifiedAt == modifiedAt &&
      other.archivedAt == archivedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, groupSeq, createdAt, modifiedAt, archivedAt);

  @override
  String toString() =>
      'Group($id, $name, seq $groupSeq${isArchived ? ', archived' : ''})';
}

/// One card of the group list or the Archive view: the Group, how many
/// Members it has, and whether it is the Active group.
final class GroupListItem {
  const GroupListItem({
    required this.group,
    required this.memberCount,
    this.isActive = false,
  });

  final Group group;
  final int memberCount;

  /// Whether this Group is the Active group (never true for an Archived
  /// group).
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      other is GroupListItem &&
      other.group == group &&
      other.memberCount == memberCount &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(group, memberCount, isActive);
}
