import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/features/expenses/domain/category.dart';
import 'package:groupay/features/expenses/domain/expense.dart';

Expense expense(Category category, int tenths, {String? description}) =>
    Expense(
      id: 'e$tenths',
      groupId: 'g',
      payerId: 'm',
      amount: Tenths(tenths),
      category: category,
      description: description,
      saveSeq: 1,
      createdAt: 1,
      modifiedAt: 1,
    );

void main() {
  group('Category', () {
    test('the fixed order, emoji and stored keys never change', () {
      expect(Category.values.map((c) => (c.key, c.emoji, c.label)), [
        ('flight', '✈️', MessageKey.categoryFlight),
        ('hotel', '🏨', MessageKey.categoryHotel),
        ('car', '🚗', MessageKey.categoryCar),
        ('fuel', '⛽', MessageKey.categoryFuel),
        ('restaurant', '🍝', MessageKey.categoryRestaurant),
        ('food_drink', '🛒', MessageKey.categoryFoodDrink),
        ('attractions', '🎡', MessageKey.categoryAttractions),
        ('other', '📝', MessageKey.categoryOther),
      ]);
    });

    test('fromKey round-trips and rejects an unknown key', () {
      for (final c in Category.values) {
        expect(Category.fromKey(c.key), c);
      }
      expect(() => Category.fromKey('groceries'), throwsStateError);
    });

    test('only Other needs a Description', () {
      expect(Category.values.where((c) => c.needsDescription), [
        Category.other,
      ]);
    });
  });

  test('the title is the Category name, or the Description for Other', () {
    expect(expense(Category.hotel, 1).title, 'מלון');
    expect(
      expense(Category.other, 1, description: 'Umbrella').title,
      'Umbrella',
    );
  });

  test('tripTotal sums the Amounts', () {
    expect(tripTotal([]), Tenths.zero);
    expect(
      tripTotal([expense(Category.hotel, 3000), expense(Category.car, 874)]),
      const Tenths(3874),
    );
  });

  test('categoryTotals: one entry per used Category, in the fixed order', () {
    expect(categoryTotals([]), isEmpty);
    expect(
      categoryTotals([
        expense(Category.other, 5, description: 'x'),
        expense(Category.hotel, 3000),
        expense(Category.hotel, 1000),
        expense(Category.flight, 20),
      ]),
      [
        (Category.flight, const Tenths(20)),
        (Category.hotel, const Tenths(4000)),
        (Category.other, const Tenths(5)),
      ],
    );
  });
}
