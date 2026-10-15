import '../models/group.dart';

class Transfer {
  final String fromId;
  final String toId;
  final int amountAgorot;

  const Transfer(this.fromId, this.toId, this.amountAgorot);

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      other.fromId == fromId &&
      other.toId == toId &&
      other.amountAgorot == amountAgorot;

  @override
  int get hashCode => Object.hash(fromId, toId, amountAgorot);

  @override
  String toString() => 'Transfer($fromId -> $toId: $amountAgorot)';
}

/// Who paid what, what each member's equal share is, and who should pay whom.
class Settlement {
  final int totalAgorot;

  /// Each member's share of the total, in agorot. Sums exactly to the total.
  final Map<String, int> shares;

  /// paid - share. Positive: is owed money. Negative: owes money.
  final Map<String, int> balances;
  final List<Transfer> transfers;

  const Settlement._(this.totalAgorot, this.shares, this.balances, this.transfers);

  factory Settlement.of(Group group) {
    final members = group.members;
    final total = group.totalAgorot;
    if (members.isEmpty) return Settlement._(total, const {}, const {}, const []);

    // Equal split; leftover agorot go one each to the first members.
    final base = total ~/ members.length;
    final remainder = total % members.length;
    final shares = {
      for (var i = 0; i < members.length; i++)
        members[i].id: base + (i < remainder ? 1 : 0),
    };

    final paid = {for (final m in members) m.id: 0};
    for (final e in group.expenses) {
      paid[e.payerId] = (paid[e.payerId] ?? 0) + e.amountAgorot;
    }
    final balances = {for (final m in members) m.id: paid[m.id]! - shares[m.id]!};

    return Settlement._(total, shares, balances, _transfers(balances));
  }

  /// Greedy: the biggest debtor pays the biggest creditor until all are settled.
  static List<Transfer> _transfers(Map<String, int> balances) {
    final debtors = [
      for (final e in balances.entries)
        if (e.value < 0) MapEntry(e.key, -e.value),
    ];
    final creditors = [
      for (final e in balances.entries)
        if (e.value > 0) MapEntry(e.key, e.value),
    ];
    final transfers = <Transfer>[];
    while (debtors.isNotEmpty && creditors.isNotEmpty) {
      debtors.sort((a, b) => b.value.compareTo(a.value));
      creditors.sort((a, b) => b.value.compareTo(a.value));
      final d = debtors.first;
      final c = creditors.first;
      final amount = d.value < c.value ? d.value : c.value;
      transfers.add(Transfer(d.key, c.key, amount));
      debtors[0] = MapEntry(d.key, d.value - amount);
      creditors[0] = MapEntry(c.key, c.value - amount);
      debtors.removeWhere((e) => e.value == 0);
      creditors.removeWhere((e) => e.value == 0);
    }
    return transfers;
  }
}
