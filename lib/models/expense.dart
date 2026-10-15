class Expense {
  final String id;
  final String payerId;

  /// Stored in agorot to avoid floating point rounding errors.
  final int amountAgorot;
  final String title;
  final String details;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.payerId,
    required this.amountAgorot,
    required this.title,
    this.details = '',
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        payerId: json['payerId'] as String,
        amountAgorot: json['amountAgorot'] as int,
        title: json['title'] as String,
        details: json['details'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'payerId': payerId,
        'amountAgorot': amountAgorot,
        'title': title,
        'details': details,
        'createdAt': createdAt.toIso8601String(),
      };
}
