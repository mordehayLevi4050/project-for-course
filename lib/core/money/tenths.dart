/// An amount of money in ₪0.10 units (AD-12). `double` never holds money.
extension type const Tenths(int value) {
  static const Tenths zero = Tenths(0);

  /// ₪1,000,000, the largest valid Expense amount (FR-11).
  static const Tenths max = Tenths(10000000);

  Tenths operator +(Tenths other) => Tenths(value + other.value);
  Tenths operator -(Tenths other) => Tenths(value - other.value);
  Tenths operator -() => Tenths(-value);
  bool operator <(Tenths other) => value < other.value;
  bool operator <=(Tenths other) => value <= other.value;
  bool operator >(Tenths other) => value > other.value;
  bool operator >=(Tenths other) => value >= other.value;

  bool get isWhole => value % 10 == 0;
}
