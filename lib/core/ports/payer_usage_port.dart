/// Tells the `groups` feature whether a Member is the Payer of any Expense
/// (FR-4, AD-2). Implemented in `expenses/data` from Story 1.3. Until then
/// `shell/` binds a stand-in that reports no Payer usage.
abstract interface class PayerUsagePort {
  Future<bool> isPayer(String groupId, String memberId);
}
