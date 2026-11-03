/// A Member of a Group (glossary: Member). Pure Dart (AD-1).
final class Member {
  const Member({
    required this.id,
    required this.groupId,
    required this.name,
    required this.memberSeq,
    required this.createdAt,
    required this.modifiedAt,
  });

  /// UUID v7.
  final String id;
  final String groupId;

  /// The normalized display name.
  final String name;

  /// Add order within the Group (MAX + 1, set once). Drives the earliest
  /// Member, payer-picker order and avatar color.
  final int memberSeq;

  /// UTC epoch millis, set once on insert.
  final int createdAt;

  /// UTC epoch millis, set on insert and on every edit.
  final int modifiedAt;

  @override
  bool operator ==(Object other) =>
      other is Member &&
      other.id == id &&
      other.groupId == groupId &&
      other.name == name &&
      other.memberSeq == memberSeq &&
      other.createdAt == createdAt &&
      other.modifiedAt == modifiedAt;

  @override
  int get hashCode =>
      Object.hash(id, groupId, name, memberSeq, createdAt, modifiedAt);

  @override
  String toString() => 'Member($id, $name, seq $memberSeq)';
}
