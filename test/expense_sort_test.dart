import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/logic/expense_sort.dart';
import 'package:groupay/models/categories.dart';
import 'package:groupay/models/expense.dart';
import 'package:groupay/models/group.dart';
import 'package:groupay/models/member.dart';

void main() {
  Expense expense(String id, String payerId, int amount, String title, DateTime createdAt) =>
      Expense(id: id, payerId: payerId, amountAgorot: amount, title: title, createdAt: createdAt);

  // Stored newest-first, like the app does.
  final group = Group(
    id: 'g',
    name: 'טיול',
    createdAt: DateTime(2025),
    members: const [
      Member(id: 'a', name: 'אבי'),
      Member(id: 'b', name: 'בני'),
      Member(id: 'c', name: 'גילה'),
    ],
    expenses: [
      expense('e3', 'c', 5000, 'מסעדה', DateTime(2026, 1, 3)),
      expense('e2', 'a', 20000, 'דלק', DateTime(2026, 1, 2)),
      expense('e1', 'b', 5000, 'משהו ישן', DateTime(2026, 1, 1)),
      expense('e0', 'a', 1000, 'דלק', DateTime(2025, 12, 31)),
    ],
  );

  List<String> ids(ExpenseSortField field, {required bool ascending}) => [
        for (final e in sortExpenses(group,
            field: field, ascending: ascending, categories: defaultCategories))
          e.id,
      ];

  test('date: descending is the original newest-first order', () {
    expect(ids(ExpenseSortField.date, ascending: false), ['e3', 'e2', 'e1', 'e0']);
    expect(ids(ExpenseSortField.date, ascending: true), ['e0', 'e1', 'e2', 'e3']);
  });

  test('amount: ties keep the original order in both directions', () {
    expect(ids(ExpenseSortField.amount, ascending: true), ['e0', 'e3', 'e1', 'e2']);
    expect(ids(ExpenseSortField.amount, ascending: false), ['e2', 'e3', 'e1', 'e0']);
  });

  test('category: by position in the list, unknown titles last', () {
    expect(ids(ExpenseSortField.category, ascending: true), ['e2', 'e0', 'e3', 'e1']);
    expect(ids(ExpenseSortField.category, ascending: false), ['e1', 'e3', 'e2', 'e0']);
  });

  test('payer: by name', () {
    expect(ids(ExpenseSortField.payer, ascending: true), ['e2', 'e0', 'e1', 'e3']);
    expect(ids(ExpenseSortField.payer, ascending: false), ['e3', 'e1', 'e2', 'e0']);
  });

  test('sorting never changes the group expenses', () {
    final before = [for (final e in group.expenses) e.id];
    for (final field in ExpenseSortField.values) {
      for (final ascending in [true, false]) {
        final sorted = sortExpenses(group, field: field, ascending: ascending);
        expect(identical(sorted, group.expenses), isFalse);
      }
    }
    expect([for (final e in group.expenses) e.id], before);
  });
}
