import '../money/tenths.dart';

/// Tells the `groups` feature each Group's Trip total, for the group-list
/// and Archive cards (AD-2: Expenses are owned by `expenses`). Implemented
/// in `expenses/data`.
abstract interface class GroupTotalsPort {
  /// The Trip total of every Group that has Expenses, by Group id. A Group
  /// with no Expenses is absent (its total is ₪0).
  Stream<Map<String, Tenths>> watchTotals();
}
