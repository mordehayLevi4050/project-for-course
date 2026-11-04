/// Tells the `groups` feature whether a Member is the Payer of any Expense
/// (FR-4, AD-2). Implemented in `expenses/data`.
abstract interface class PayerUsagePort {
  Future<bool> isPayer(String groupId, String memberId);
}
