import 'expense.dart';
import 'member.dart';

class Group {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<Member> members;
  final List<Expense> expenses;

  const Group({
    required this.id,
    required this.name,
    required this.createdAt,
    this.members = const [],
    this.expenses = const [],
  });

  int get totalAgorot => expenses.fold(0, (sum, e) => sum + e.amountAgorot);

  Member? memberById(String id) {
    for (final m in members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Group copyWith({List<Member>? members, List<Expense>? expenses}) => Group(
        id: id,
        name: name,
        createdAt: createdAt,
        members: members ?? this.members,
        expenses: expenses ?? this.expenses,
      );

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        members: [
          for (final m in json['members'] as List? ?? const [])
            Member.fromJson(m as Map<String, dynamic>),
        ],
        expenses: [
          for (final e in json['expenses'] as List? ?? const [])
            Expense.fromJson(e as Map<String, dynamic>),
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'members': [for (final m in members) m.toJson()],
        'expenses': [for (final e in expenses) e.toJson()],
      };
}
