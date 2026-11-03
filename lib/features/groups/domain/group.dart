/// A trip Group (glossary: Group). Pure Dart (AD-1).
final class Group {
  const Group({
    required this.id,
    required this.name,
    required this.groupSeq,
    required this.createdAt,
    required this.modifiedAt,
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

  @override
  bool operator ==(Object other) =>
      other is Group &&
      other.id == id &&
      other.name == name &&
      other.groupSeq == groupSeq &&
      other.createdAt == createdAt &&
      other.modifiedAt == modifiedAt;

  @override
  int get hashCode => Object.hash(id, name, groupSeq, createdAt, modifiedAt);

  @override
  String toString() => 'Group($id, $name, seq $groupSeq)';
}

/// One card of the group list: the Group and how many Members it has.
final class GroupListItem {
  const GroupListItem({required this.group, required this.memberCount});

  final Group group;
  final int memberCount;

  @override
  bool operator ==(Object other) =>
      other is GroupListItem &&
      other.group == group &&
      other.memberCount == memberCount;

  @override
  int get hashCode => Object.hash(group, memberCount);
}
