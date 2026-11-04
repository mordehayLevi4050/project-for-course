import '../../../core/i18n/message_key.dart';

/// The Category of an Expense (glossary: Category), in the fixed order of
/// the Category grid. Pure Dart (AD-1).
///
/// [key] is what the database stores: it is stable and is never renamed or
/// localized (AD-18). [emoji] is the tile and row icon.
enum Category {
  flight('flight', '✈️', MessageKey.categoryFlight),
  hotel('hotel', '🏨', MessageKey.categoryHotel),
  car('car', '🚗', MessageKey.categoryCar),
  fuel('fuel', '⛽', MessageKey.categoryFuel),
  restaurant('restaurant', '🍝', MessageKey.categoryRestaurant),
  foodDrink('food_drink', '🛒', MessageKey.categoryFoodDrink),
  attractions('attractions', '🎡', MessageKey.categoryAttractions),
  other('other', '📝', MessageKey.categoryOther);

  const Category(this.key, this.emoji, this.label);

  /// The stored key.
  final String key;
  final String emoji;

  /// The Category name shown on tiles and as the row title.
  final MessageKey label;

  /// *Other* needs a Description, and is the only Category that stores one.
  bool get needsDescription => this == other;

  /// The Category stored as [key]. An unknown key is a bug and throws a
  /// [StateError].
  static Category fromKey(String key) => values.firstWhere(
    (c) => c.key == key,
    orElse: () => throw StateError('Unknown Category key "$key"'),
  );
}
