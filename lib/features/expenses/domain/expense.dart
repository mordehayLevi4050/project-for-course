import '../../../core/money/tenths.dart';
import 'category.dart';

/// One Expense of a Group (glossary: Expense). Pure Dart (AD-1). It holds no
/// participant list: it is split among all current Members.
final class Expense {
  const Expense({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.amount,
    required this.category,
    required this.saveSeq,
    required this.createdAt,
    required this.modifiedAt,
    this.description,
  });

  /// UUID v7.
  final String id;
  final String groupId;

  /// The Member who paid.
  final String payerId;
  final Tenths amount;
  final Category category;

  /// Set only for [Category.other].
  final String? description;

  /// Save order within the Group (MAX + 1, set once). Drives the list order
  /// and the default Payer; never the clock.
  final int saveSeq;

  /// UTC epoch millis of the first save; never changed by an edit.
  final int createdAt;

  /// UTC epoch millis, set on insert and on every edit.
  final int modifiedAt;

  /// The row title: the Description for *Other*, otherwise the Category
  /// name.
  String get title => description ?? category.label.text;

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.groupId == groupId &&
      other.payerId == payerId &&
      other.amount == amount &&
      other.category == category &&
      other.description == description &&
      other.saveSeq == saveSeq &&
      other.createdAt == createdAt &&
      other.modifiedAt == modifiedAt;

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    payerId,
    amount,
    category,
    description,
    saveSeq,
    createdAt,
    modifiedAt,
  );

  @override
  String toString() =>
      'Expense($id, ${category.key}, ${amount.value}, payer $payerId, '
      'seq $saveSeq)';
}

/// The Trip total of [expenses].
Tenths tripTotal(Iterable<Expense> expenses) =>
    expenses.fold(Tenths.zero, (sum, e) => sum + e.amount);

/// Each Category's total in [expenses], in the fixed Category order, for the
/// category share stripe. Categories with no Expense are left out.
List<(Category, Tenths)> categoryTotals(Iterable<Expense> expenses) {
  final totals = <Category, Tenths>{};
  for (final e in expenses) {
    totals[e.category] = (totals[e.category] ?? Tenths.zero) + e.amount;
  }
  return [
    for (final c in Category.values)
      if (totals[c] case final total?) (c, total),
  ];
}
