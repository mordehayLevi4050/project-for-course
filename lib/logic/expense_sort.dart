import '../models/expense.dart';
import '../models/group.dart';

enum ExpenseSortField { date, amount, category, payer }

/// Returns the group's expenses sorted by [field] in the given direction,
/// as a new list; the group's own list is never changed. Expenses that compare
/// equal keep their original (newest-first) order.
///
/// Categories sort by their position in [categories]; titles that are not in
/// the list (e.g. free text from before categories existed) come last, by name.
/// Payers sort by name.
List<Expense> sortExpenses(
  Group group, {
  required ExpenseSortField field,
  required bool ascending,
  List<String> categories = const [],
}) {
  int categoryIndex(Expense e) {
    final i = categories.indexOf(e.title);
    return i == -1 ? categories.length : i;
  }

  String payerName(Expense e) => group.memberById(e.payerId)?.name ?? '';

  int compare((int, Expense) a, (int, Expense) b) {
    final (ai, ae) = a;
    final (bi, be) = b;
    return switch (field) {
      // The stored list is newest-first, so a later index is an older expense.
      // (createdAt can tie for expenses added in the same instant.)
      ExpenseSortField.date => bi.compareTo(ai),
      ExpenseSortField.amount => ae.amountAgorot.compareTo(be.amountAgorot),
      ExpenseSortField.category => categoryIndex(ae) != categoryIndex(be)
          ? categoryIndex(ae).compareTo(categoryIndex(be))
          : ae.title.compareTo(be.title),
      ExpenseSortField.payer => payerName(ae).compareTo(payerName(be)),
    };
  }

  // List.sort is not stable, so ties are broken by the original index.
  final indexed = group.expenses.indexed.toList()
    ..sort((a, b) {
      final c = compare(a, b);
      if (c != 0) return ascending ? c : -c;
      return a.$1.compareTo(b.$1);
    });
  return [for (final (_, e) in indexed) e];
}
