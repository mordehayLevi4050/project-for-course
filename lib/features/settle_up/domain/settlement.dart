import '../../../core/money/tenths.dart';
import '../../../core/text/collation.dart';
import '../../expenses/domain/expense.dart';
import '../../groups/domain/member.dart';

/// One Transfer of the Summary (glossary: Transfer): the debtor pays the
/// receiver [amount]. Pure Dart (AD-1).
final class Transfer {
  const Transfer({
    required this.debtorId,
    required this.receiverId,
    required this.amount,
  });

  final String debtorId;
  final String receiverId;

  /// Always more than zero.
  final Tenths amount;

  @override
  bool operator ==(Object other) =>
      other is Transfer &&
      other.debtorId == debtorId &&
      other.receiverId == receiverId &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(debtorId, receiverId, amount);

  @override
  String toString() => 'Transfer($debtorId → $receiverId, ${amount.value})';
}

/// The result of [settle]: the Share and the Transfer list, in Summary
/// order.
final class Settlement {
  const Settlement({required this.share, required this.transfers});

  /// The Trip total divided by the number of Members, rounded down.
  final Tenths share;

  /// Sorted by debtor name, then receiver name (`compareNames`). Empty
  /// exactly when every Balance is zero.
  final List<Transfer> transfers;

  @override
  String toString() => 'Settlement(share ${share.value}, $transfers)';
}

/// FR-15 (transfer-calculation.md): the Share and the minimal Transfer list
/// of one snapshot of a Group's [members] and [expenses].
///
/// The Group has at least one Member (the caller checks `maySummarize`), and
/// every Expense's Payer is one of [members]; otherwise it is a bug and an
/// [ArgumentError] is thrown.
Settlement settle(List<Member> members, List<Expense> expenses) {
  final (:share, :balances) = settledBalances(members, expenses);
  return Settlement(
    share: share,
    transfers: minimalTransfers(members, balances),
  );
}

/// Steps 1–5 of transfer-calculation.md: the Share, and each Member's
/// Balance (paid minus Share) after the Leftover is taken off the receivers.
/// The Balances add up to exactly zero.
({Tenths share, Map<String, Tenths> balances}) settledBalances(
  List<Member> members,
  List<Expense> expenses,
) {
  if (members.isEmpty) {
    throw ArgumentError.value(members, 'members', 'must not be empty');
  }
  final paid = {for (final m in members) m.id: 0};
  // The lowest saveSeq among the Expenses each Member pays now.
  final firstSeq = <String, int>{};
  var total = 0;
  for (final e in expenses) {
    final sum = paid[e.payerId];
    if (sum == null) {
      throw ArgumentError.value(e, 'expenses', 'Payer is not a Member');
    }
    paid[e.payerId] = sum + e.amount.value;
    total += e.amount.value;
    final seq = firstSeq[e.payerId];
    if (seq == null || e.saveSeq < seq) firstSeq[e.payerId] = e.saveSeq;
  }

  final share = total ~/ members.length;
  final balance = {for (final m in members) m.id: paid[m.id]! - share};
  var leftover = total - share * members.length;

  // Receivers absorb the Leftover: smallest total paid first; between equal
  // totals, the one whose first Expense was saved later first. Names are
  // never used here, and neither is the clock.
  final receivers =
      [
        for (final m in members)
          if (balance[m.id]! > 0) m.id,
      ]..sort((a, b) {
        final byPaid = paid[a]!.compareTo(paid[b]!);
        if (byPaid != 0) return byPaid;
        return firstSeq[b]!.compareTo(firstSeq[a]!);
      });
  for (final id in receivers) {
    if (leftover == 0) break;
    final take = leftover < balance[id]! ? leftover : balance[id]!;
    balance[id] = balance[id]! - take;
    leftover -= take;
  }

  return (
    share: Tenths(share),
    balances: {for (final e in balance.entries) e.key: Tenths(e.value)},
  );
}

/// Steps 6–7 of transfer-calculation.md: the fewest Transfers that settle
/// [balances] (which add up to zero), each from a negative Balance to a
/// positive one, and among those the list whose (debtor, receiver) sequence
/// comes first under `compareNames`, in that order.
///
/// An exact search, never greedy: the most zero-sum blocks the Balances can
/// be split into fixes the minimum (non-zero Balances − blocks). Every
/// minimal list is a set of trees, one per block of such a split, so every
/// maximal split is tried, and inside each block the spanning trees are
/// searched in lexicographic order of their sorted pairs for the first one
/// whose flows all run from debtor to receiver. A tree's flows are fixed by
/// the Balances, so its pairs identify it.
List<Transfer> minimalTransfers(
  List<Member> members,
  Map<String, Tenths> balances,
) {
  // Members with a non-zero Balance, in name order; the index is the rank.
  final nodes = [
    for (final m in members)
      if ((balances[m.id] ?? Tenths.zero).value != 0) m,
  ]..sort(_byName);
  final n = nodes.length;
  if (n == 0) return const [];
  final bal = [for (final m in nodes) balances[m.id]!.value];
  if (bal.fold(0, (a, b) => a + b) != 0) {
    throw ArgumentError.value(balances, 'balances', 'must add up to zero');
  }

  final full = (1 << n) - 1;
  final sum = List<int>.filled(full + 1, 0);
  for (var mask = 1; mask <= full; mask++) {
    final low = mask & -mask;
    sum[mask] = sum[mask ^ low] + bal[low.bitLength - 1];
  }

  // blocks[mask]: the most zero-sum blocks that partition mask, or -1.
  final blocks = List<int>.filled(full + 1, -1);
  blocks[0] = 0;
  for (var mask = 1; mask <= full; mask++) {
    if (sum[mask] != 0) continue;
    final low = mask & -mask;
    final rest = mask ^ low;
    var best = -1;
    // Every sub-mask of mask that holds its lowest member.
    var sub = rest;
    while (true) {
      final part = sub | low;
      if (sum[part] == 0) {
        final other = blocks[mask ^ part];
        if (other >= 0 && other + 1 > best) best = other + 1;
      }
      if (sub == 0) break;
      sub = (sub - 1) & rest;
    }
    blocks[mask] = best;
  }

  final treeCache = <int, List<_Edge>>{};
  List<_Edge>? bestEdges;

  void search(int mask, List<_Edge> chosen) {
    if (mask == 0) {
      final edges = [...chosen]..sort(_Edge.compare);
      if (bestEdges == null || _compareSequences(edges, bestEdges!) < 0) {
        bestEdges = edges;
      }
      return;
    }
    final low = mask & -mask;
    final rest = mask ^ low;
    final want = blocks[mask] - 1;
    var sub = rest;
    while (true) {
      final part = sub | low;
      // A block of a maximal split cannot be split further itself.
      if (sum[part] == 0 && blocks[part] == 1 && blocks[mask ^ part] == want) {
        final tree = treeCache[part] ??= _firstTree(part, bal);
        search(mask ^ part, [...chosen, ...tree]);
      }
      if (sub == 0) break;
      sub = (sub - 1) & rest;
    }
  }

  search(full, const []);
  return [
    for (final e in bestEdges!)
      Transfer(
        debtorId: nodes[e.debtor].id,
        receiverId: nodes[e.receiver].id,
        amount: Tenths(e.amount),
      ),
  ];
}

int _byName(Member a, Member b) {
  final byName = compareNames(a.name, b.name);
  return byName != 0 ? byName : a.memberSeq.compareTo(b.memberSeq);
}

/// A Transfer between two ranks (indexes in name order).
final class _Edge {
  const _Edge(this.debtor, this.receiver, this.amount);

  final int debtor;
  final int receiver;
  final int amount;

  static int compare(_Edge a, _Edge b) {
    final byDebtor = a.debtor.compareTo(b.debtor);
    return byDebtor != 0 ? byDebtor : a.receiver.compareTo(b.receiver);
  }
}

int _compareSequences(List<_Edge> a, List<_Edge> b) {
  for (var i = 0; i < a.length && i < b.length; i++) {
    final c = _Edge.compare(a[i], b[i]);
    if (c != 0) return c;
  }
  return a.length.compareTo(b.length);
}

/// The lexicographically first spanning tree of one block (a zero-sum set
/// of ranks with no zero-sum part) whose flows all go from a debtor to a
/// receiver.
///
/// Candidate pairs are tried in (debtor, receiver) order, each taken before
/// it is skipped, so the first valid tree found is the first in order. A
/// valid tree always exists (a block can always be settled with
/// size − 1 Transfers), so this never fails.
List<_Edge> _firstTree(int block, List<int> bal) {
  final ranks = [
    for (var i = 0; i < bal.length; i++)
      if (block & (1 << i) != 0) i,
  ];
  final debtors = [
    for (final r in ranks)
      if (bal[r] < 0) r,
  ];
  final receivers = [
    for (final r in ranks)
      if (bal[r] > 0) r,
  ];
  // Local vertex ids: debtors 0..d-1, receivers d..d+r-1.
  final d = debtors.length;
  final size = ranks.length;
  final localBal = [
    for (final r in debtors) bal[r],
    for (final r in receivers) bal[r],
  ];
  final pairU = <int>[];
  final pairV = <int>[];
  for (var i = 0; i < d; i++) {
    for (var j = 0; j < receivers.length; j++) {
      pairU.add(i);
      pairV.add(d + j);
    }
  }
  final pairCount = pairU.length;
  final need = size - 1;
  // The index just past each debtor's last pair.
  final debtorEnd = [for (var i = 0; i < d; i++) (i + 1) * receivers.length];

  final comp = List<int>.generate(size, (i) => i);
  final degree = List<int>.filled(size, 0);
  final chosen = <int>[];
  List<int>? flows;

  bool dfs(int index) {
    if (chosen.length == need) {
      flows = _treeFlows(chosen, pairU, pairV, localBal, d);
      return flows != null;
    }
    if (pairCount - index < need - chosen.length) return false;
    final u = pairU[index];
    final v = pairV[index];
    final cu = comp[u];
    final cv = comp[v];
    final lastOfDebtor = index + 1 == debtorEnd[u];
    if (cu != cv) {
      // Take the pair: merge the two components.
      final saved = List<int>.of(comp);
      for (var k = 0; k < size; k++) {
        if (comp[k] == cv) comp[k] = cu;
      }
      chosen.add(index);
      degree[u]++;
      degree[v]++;
      if (dfs(index + 1)) return true;
      degree[u]--;
      degree[v]--;
      chosen.removeLast();
      comp.setAll(0, saved);
    }
    // Skip the pair, unless the debtor would be left with no Transfer.
    if (lastOfDebtor && degree[u] == 0) return false;
    return dfs(index + 1);
  }

  if (!dfs(0)) {
    throw StateError('No debtor-to-receiver tree for block $block');
  }
  return [
    for (var k = 0; k < chosen.length; k++)
      _Edge(
        debtors[pairU[chosen[k]]],
        receivers[pairV[chosen[k]] - d],
        flows![k],
      ),
  ];
}

/// The flow on each chosen pair of a spanning tree, found by peeling
/// leaves, or `null` when some flow would not run from the debtor (local
/// id < [d]) to the receiver with an amount above zero.
List<int>? _treeFlows(
  List<int> chosen,
  List<int> pairU,
  List<int> pairV,
  List<int> balances,
  int d,
) {
  final size = balances.length;
  final rem = List<int>.of(balances);
  final degree = List<int>.filled(size, 0);
  final incident = List<List<int>>.generate(size, (_) => <int>[]);
  for (var k = 0; k < chosen.length; k++) {
    final p = chosen[k];
    degree[pairU[p]]++;
    degree[pairV[p]]++;
    incident[pairU[p]].add(k);
    incident[pairV[p]].add(k);
  }
  final used = List<bool>.filled(chosen.length, false);
  final flows = List<int>.filled(chosen.length, 0);
  final leaves = [
    for (var v = 0; v < size; v++)
      if (degree[v] == 1) v,
  ];
  var done = 0;
  while (leaves.isNotEmpty && done < chosen.length) {
    final v = leaves.removeLast();
    if (degree[v] != 1) continue;
    final k = incident[v].firstWhere((k) => !used[k]);
    final p = chosen[k];
    final isDebtor = v < d;
    final other = isDebtor ? pairV[p] : pairU[p];
    // A debtor leaf sends its whole Balance; a receiver leaf gets its own.
    final flow = isDebtor ? -rem[v] : rem[v];
    if (flow <= 0) return null;
    flows[k] = flow;
    used[k] = true;
    done++;
    rem[other] += rem[v];
    rem[v] = 0;
    degree[v] = 0;
    degree[other]--;
    if (degree[other] == 1) leaves.add(other);
  }
  return flows;
}
