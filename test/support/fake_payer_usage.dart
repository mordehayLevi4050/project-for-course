import 'package:groupay/core/ports/payer_usage_port.dart';

/// A [PayerUsagePort] whose Payers the test sets by Member id.
final class FakePayerUsage implements PayerUsagePort {
  FakePayerUsage([Set<String>? payers]) : payers = payers ?? {};

  /// The ids of Members who paid for an Expense.
  final Set<String> payers;

  /// Every call made, as (groupId, memberId).
  final calls = <(String, String)>[];

  @override
  Future<bool> isPayer(String groupId, String memberId) async {
    calls.add((groupId, memberId));
    return payers.contains(memberId);
  }
}
