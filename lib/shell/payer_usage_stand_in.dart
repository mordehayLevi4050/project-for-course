import '../core/ports/payer_usage_port.dart';

/// Bound until Story 1.3 adds Expenses and the real `expenses/data`
/// implementation: with no Expenses, no Member is a Payer.
final class NoPayerUsage implements PayerUsagePort {
  const NoPayerUsage();

  @override
  Future<bool> isPayer(String groupId, String memberId) async => false;
}
