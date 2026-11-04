import 'package:flutter/painting.dart';

import '../../../core/ui/theme/tokens.dart';
import '../domain/category.dart';

/// The fixed color of each Category (DESIGN.md › Colors). Used only as a
/// non-text mark: the row edge, the emoji tint, the selected tile and the
/// share stripe.
Color categoryColor(Category category) => switch (category) {
  Category.flight => AppColors.categoryFlight,
  Category.hotel => AppColors.categoryHotel,
  Category.car => AppColors.categoryCar,
  Category.fuel => AppColors.categoryFuel,
  Category.restaurant => AppColors.categoryRestaurant,
  Category.foodDrink => AppColors.categoryFoodDrink,
  Category.attractions => AppColors.categoryAttractions,
  Category.other => AppColors.categoryOther,
};
