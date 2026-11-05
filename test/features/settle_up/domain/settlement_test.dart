import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/core/text/collation.dart';
import 'package:groupay/features/expenses/domain/category.dart';
import 'package:groupay/features/expenses/domain/expense.dart';
import 'package:groupay/features/groups/domain/member.dart';
import 'package:groupay/features/settle_up/domain/settlement.dart';

/// Members named [names], in that add order; each id is the name.
List<Member> membersOf(List<String> names) => [
  for (var i = 0; i < names.length; i++)
    Member(
      id: names[i],
      groupId: 'g',
      name: names[i],
      memberSeq: i + 1,
      createdAt: 0,
      modifiedAt: 0,
    ),
];

/// Expenses in save order: (payer id, amount in tenths). `saveSeq` follows
/// the list; [createdAt] can be given to show the clock is ignored.
List<Expense> expensesOf(List<(String, int)> paid, {List<int>? createdAt}) => [
  for (var i = 0; i < paid.length; i++)
    Expense(
      id: 'e$i',
      groupId: 'g',
      payerId: paid[i].$1,
      amount: Tenths(paid[i].$2),
      category: Category.restaurant,
      saveSeq: i + 1,
      createdAt: createdAt?[i] ?? i,
      modifiedAt: createdAt?[i] ?? i,
    ),
];

/// The Transfers as (debtor, receiver, tenths), with ids = names.
List<(String, String, int)> run(
  List<String> names,
  List<(String, int)> paid, {
  List<int>? createdAt,
}) => [
  for (final t in settle(
    membersOf(names),
    expensesOf(paid, createdAt: createdAt),
  ).transfers)
    (t.debtorId, t.receiverId, t.amount.value),
];

void main() {
  group('EARS calculation cases (epics.md T3.x)', () {
    test('T3.1 Dana 300, Yossi 0, Noa 0', () {
      expect(run(['Dana', 'Yossi', 'Noa'], [('Dana', 3000)]), [
        ('Noa', 'Dana', 1000),
        ('Yossi', 'Dana', 1000),
      ]);
    });

    test('T3.3 Dana 100, Yossi 100: no Transfers', () {
      expect(run(['Dana', 'Yossi'], [('Dana', 1000), ('Yossi', 1000)]), []);
    });

    test('T3.4 Dana 100, Yossi 0, Noa 0: Leftover from Dana', () {
      final s = settle(
        membersOf(['Dana', 'Yossi', 'Noa']),
        expensesOf([('Dana', 1000)]),
      );
      expect(s.share, const Tenths(333));
      expect(run(['Dana', 'Yossi', 'Noa'], [('Dana', 1000)]), [
        ('Noa', 'Dana', 333),
        ('Yossi', 'Dana', 333),
      ]);
    });

    test('T3.5 Dana 87.4, Yossi 0', () {
      expect(run(['Dana', 'Yossi'], [('Dana', 874)]), [('Yossi', 'Dana', 437)]);
    });

    test('T3.6 מוטי 400, דנה 200, יוסי 0, נועה 0', () {
      expect(
        run(['מוטי', 'דנה', 'יוסי', 'נועה'], [('מוטי', 4000), ('דנה', 2000)]),
        [('יוסי', 'דנה', 500), ('יוסי', 'מוטי', 1000), ('נועה', 'מוטי', 1500)],
      );
    });

    test('T3.15 Dana 33.4, Yossi 33.3, Noa 33.3: no Transfers', () {
      expect(
        run(
          ['Dana', 'Yossi', 'Noa'],
          [('Dana', 334), ('Yossi', 333), ('Noa', 333)],
        ),
        [],
      );
    });

    test('T3.16 Dana 100.5, Yossi 100', () {
      expect(run(['Dana', 'Yossi'], [('Dana', 1005), ('Yossi', 1000)]), [
        ('Yossi', 'Dana', 2),
      ]);
    });

    test('T3.18 Dana 101.5, Yossi 100, Noa 100', () {
      expect(
        run(
          ['Dana', 'Yossi', 'Noa'],
          [('Dana', 1015), ('Yossi', 1000), ('Noa', 1000)],
        ),
        [('Noa', 'Dana', 5), ('Yossi', 'Dana', 5)],
      );
    });

    test('T3.19 Dana 3, Yossi 0, Noa 0, Avi 0', () {
      expect(run(['Dana', 'Yossi', 'Noa', 'Avi'], [('Dana', 30)]), [
        ('Avi', 'Dana', 7),
        ('Noa', 'Dana', 7),
        ('Yossi', 'Dana', 7),
      ]);
    });

    test('T3.20 Zoe 400, דנה 200, Adam 0, יוסי 0', () {
      expect(
        run(['Zoe', 'דנה', 'Adam', 'יוסי'], [('Zoe', 4000), ('דנה', 2000)]),
        [('יוסי', 'דנה', 500), ('יוסי', 'Zoe', 1000), ('Adam', 'Zoe', 1500)],
      );
    });

    test('T3.31 אבי 100.1, גיל 100, בני 0, דוד 0', () {
      expect(
        run(['אבי', 'גיל', 'בני', 'דוד'], [('אבי', 1001), ('גיל', 1000)]),
        [('בני', 'אבי', 1), ('בני', 'גיל', 499), ('דוד', 'אבי', 500)],
      );
    });

    test('T3.32 אברהם 60, יצחק 40, יעקב 0', () {
      expect(run(['אברהם', 'יצחק', 'יעקב'], [('אברהם', 600), ('יצחק', 400)]), [
        ('יעקב', 'אברהם', 267),
        ('יעקב', 'יצחק', 66),
      ]);
    });

    test('T3.33 / T3.39 equal totals: the later first Expense absorbs', () {
      expect(run(['אברהם', 'יצחק', 'יעקב'], [('אברהם', 500), ('יצחק', 500)]), [
        ('יעקב', 'אברהם', 167),
        ('יעקב', 'יצחק', 166),
      ]);
    });

    test('T3.35 אבי 30.2, בני 10.1, גיל 0, דוד 0', () {
      expect(run(['אבי', 'בני', 'גיל', 'דוד'], [('אבי', 302), ('בני', 101)]), [
        ('גיל', 'אבי', 100),
        ('דוד', 'אבי', 100),
      ]);
    });

    test("T3.37 מוטי 400, דנה 200, גיל 0, ג'ני 0", () {
      expect(
        run(['מוטי', 'דנה', 'גיל', "ג'ני"], [('מוטי', 4000), ('דנה', 2000)]),
        [('גיל', 'דנה', 500), ('גיל', 'מוטי', 1000), ("ג'ני", 'מוטי', 1500)],
      );
    });

    test('T3.38 מוטי 400, נועה 200, דניאל 0, דני2 0', () {
      expect(
        run(
          ['מוטי', 'נועה', 'דניאל', 'דני2'],
          [('מוטי', 4000), ('נועה', 2000)],
        ),
        [
          ('דניאל', 'מוטי', 1000),
          ('דניאל', 'נועה', 500),
          ('דני2', 'מוטי', 1500),
        ],
      );
    });
  });

  group('rename and clock', () {
    test('T3.17 T3.6 with יוסי renamed to שי', () {
      final before = settledBalances(
        membersOf(['מוטי', 'דנה', 'יוסי', 'נועה']),
        expensesOf([('מוטי', 4000), ('דנה', 2000)]),
      ).balances;
      final names = ['מוטי', 'דנה', 'שי', 'נועה'];
      final paid = [('מוטי', 4000), ('דנה', 2000)];
      expect(run(names, paid), [
        ('נועה', 'דנה', 500),
        ('נועה', 'מוטי', 1000),
        ('שי', 'מוטי', 1500),
      ]);
      final after = settledBalances(membersOf(names), expensesOf(paid));
      expect(after.balances['שי'], before['יוסי']);
      expect(after.balances['מוטי'], before['מוטי']);
      expect(after.balances['דנה'], before['דנה']);
      expect(after.balances['נועה'], before['נועה']);
    });

    test('T3.34 T3.33 with אברהם renamed to תום', () {
      expect(run(['תום', 'יצחק', 'יעקב'], [('תום', 500), ('יצחק', 500)]), [
        ('יעקב', 'יצחק', 166),
        ('יעקב', 'תום', 167),
      ]);
    });

    test('T3.40 / T3.45 order by saveSeq only, never the clock', () {
      // יצחק saved first; then the clock went back a day for אברהם.
      final day = 24 * 60 * 60 * 1000;
      expect(
        run(
          ['אברהם', 'יצחק', 'יעקב'],
          [('יצחק', 500), ('אברהם', 500)],
          createdAt: [10 * day, 9 * day],
        ),
        [('יעקב', 'אברהם', 166), ('יעקב', 'יצחק', 167)],
      );
      // Any shift of every time (a time zone change) changes nothing.
      expect(
        run(
          ['אברהם', 'יצחק', 'יעקב'],
          [('אברהם', 500), ('יצחק', 500)],
          createdAt: [5 * day + 3, 1],
        ),
        [('יעקב', 'אברהם', 167), ('יעקב', 'יצחק', 166)],
      );
    });

    test('first Expense = lowest saveSeq among the Expenses paid now', () {
      // A paid seq 1 and 3, B paid seq 2: A's first is earlier, so B absorbs.
      expect(run(['A', 'B', 'C'], [('A', 250), ('B', 500), ('A', 250)]), [
        ('C', 'A', 167),
        ('C', 'B', 166),
      ]);
    });
  });

  group('Share and Leftover', () {
    test('uneven tenths: Share rounds down, Balances add up to zero', () {
      final r = settledBalances(
        membersOf(['A', 'B', 'C']),
        expensesOf([('A', 1), ('B', 1)]),
      );
      expect(r.share, Tenths.zero);
      expect(r.balances.values.fold(0, (a, b) => a + b.value), 0);
      expect(run(['A', 'B', 'C'], [('A', 1), ('B', 1)]), []);
    });

    test('₪0.1 is shown (no minimum Transfer)', () {
      expect(run(['A', 'B'], [('A', 2)]), [('B', 'A', 1)]);
    });

    test('Leftover over several receivers, debtors untouched', () {
      // Total 30.6 / 7 = 4.3 (Leftover 0.5). B paid 4.4 (+0.1) gives 0.1,
      // C paid 5 (+0.7) gives the remaining 0.4; A paid 21.2 keeps +16.9.
      final r = settledBalances(
        membersOf(['A', 'B', 'C', 'D', 'E', 'F', 'G']),
        expensesOf([('A', 212), ('B', 44), ('C', 50)]),
      );
      expect(r.share, const Tenths(43));
      expect(r.balances['B'], Tenths.zero);
      expect(r.balances['C'], const Tenths(3));
      expect(r.balances['A'], const Tenths(169));
      for (final d in ['D', 'E', 'F', 'G']) {
        expect(r.balances[d], const Tenths(-43));
      }
    });

    test('no Expenses: Share 0 and no Transfers', () {
      final s = settle(membersOf(['A', 'B']), const []);
      expect(s.share, Tenths.zero);
      expect(s.transfers, isEmpty);
    });
  });

  group('ties between minimal lists', () {
    test('Hebrew names: alphabet order picks the pairs', () {
      // Share 12.5: two debtors of 12.5, receivers of 2.5 and 22.5, so
      // three Transfers either way.
      expect(run(['אבי', 'בני', 'גיל', 'דוד'], [('גיל', 150), ('דוד', 350)]), [
        ('אבי', 'גיל', 25),
        ('אבי', 'דוד', 100),
        ('בני', 'דוד', 125),
      ]);
    });

    test('Latin names sort after Hebrew, ignoring case', () {
      expect(run(['adam', 'Ben', 'גיל', 'דוד'], [('גיל', 150), ('דוד', 350)]), [
        ('adam', 'גיל', 25),
        ('adam', 'דוד', 100),
        ('Ben', 'דוד', 125),
      ]);
    });

    test('mixed names: a Hebrew debtor before a Latin one', () {
      expect(
        run(['Zoe', 'נועה', 'Adam', 'דנה'], [('Adam', 150), ('דנה', 350)]),
        [('נועה', 'דנה', 100), ('נועה', 'Adam', 25), ('Zoe', 'דנה', 125)],
      );
    });

    test('zero-sum blocks are settled separately', () {
      // B is settled already; A and C both pay D.
      expect(
        run(['A', 'B', 'C', 'D'], [('B', 200), ('D', 600)]),
        // Share ₪20: A −20, B 0, C −20, D +40.
        [('A', 'D', 200), ('C', 'D', 200)],
      );
      expect(
        run(
          ['A', 'B', 'C', 'D', 'E', 'F'],
          [('B', 300), ('D', 900), ('F', 600)],
        ),
        // Share ₪30: A −30, B 0, C −30, D +60, E −30, F +30. Three maximal
        // splits ({A,F}, {C,F} or {E,F} with the rest); {E,F} gives the
        // first pairs.
        [('A', 'D', 300), ('C', 'D', 300), ('E', 'F', 300)],
      );
    });
  });

  group('random Groups of 2 to 10 Members', () {
    test('sizes 2 to 6 match a brute-force oracle', () {
      final random = Random(42);
      for (var size = 2; size <= 6; size++) {
        for (var round = 0; round < 150; round++) {
          final names = _randomNames(random, size);
          final paid = [
            for (var e = 0; e < random.nextInt(6); e++)
              (names[random.nextInt(size)], 1 + random.nextInt(400)),
          ];
          final members = membersOf(names);
          final expenses = expensesOf(paid);
          final balances = settledBalances(members, expenses).balances;
          final actual = settle(members, expenses).transfers;
          final expected = _oracle(members, balances);
          expect(
            [
              for (final t in actual)
                (t.debtorId, t.receiverId, t.amount.value),
            ],
            expected,
            reason: 'names $names, paid $paid',
          );
        }
      }
    });

    test('sizes 7 to 10 settle every Balance with the fewest Transfers', () {
      final random = Random(7);
      for (var size = 7; size <= 10; size++) {
        for (var round = 0; round < 60; round++) {
          final names = _randomNames(random, size);
          // Odd rounds use a few coarse amounts, so zero-sum blocks (where
          // a greedy answer needs extra Transfers) are common.
          final coarse = round.isOdd;
          final paid = [
            for (var e = 0; e < 1 + random.nextInt(12); e++)
              (
                names[random.nextInt(size)],
                coarse
                    ? size * 10 * (1 + random.nextInt(3))
                    : 1 + random.nextInt(5000),
              ),
          ];
          final members = membersOf(names);
          final expenses = expensesOf(paid);
          final balances = settledBalances(members, expenses).balances;
          final transfers = settle(members, expenses).transfers;
          _expectSettles(balances, transfers);
          // Minimal count = non-zero Balances − the most zero-sum blocks,
          // found here by a separate plain recursion.
          final nonZero = [
            for (final b in balances.values)
              if (b.value != 0) b.value,
          ];
          expect(
            transfers.length,
            nonZero.length - _mostZeroSumBlocks(nonZero),
            reason: 'names $names, paid $paid',
          );
        }
      }
    });
  });

  test('10 Members, 5 debtors and 5 receivers with no zero-sum part: ≤ 1s', () {
    // A..E paid much, F..J little, with no zero-sum part among the
    // Balances, so the minimum is 9 Transfers.
    final names = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
    List<(String, int)> paidBy(List<int> amounts) => [
      for (var i = 0; i < amounts.length; i++) (names[i], amounts[i]),
    ];
    final cases = [
      paidBy([19234, 16263, 9333, 19784, 21151, 398, 1037, 376, 659, 199]),
      paidBy([20492, 9080, 17848, 9608, 7596, 1422, 1178, 721, 1, 1203]),
      paidBy([10848, 11982, 13595, 19803, 16624, 558, 948, 1386, 1148, 76]),
      // The slowest of 20,000 random 10-Member Groups.
      paidBy([5762, 2908, 5425, 5748, 48, 3595, 124, 5571, 36, 12]),
    ];
    for (final (i, paid) in cases.indexed) {
      final members = membersOf(names);
      final expenses = expensesOf(paid);
      final watch = Stopwatch()..start();
      final s = settle(members, expenses);
      watch.stop();
      expect(watch.elapsedMilliseconds, lessThanOrEqualTo(1000));
      final balances = settledBalances(members, expenses).balances;
      _expectSettles(balances, s.transfers);
      if (i < 3) expect(s.transfers.length, 9);
    }
  });

  test('random 10-Member Groups each settle within 1s', () {
    final random = Random(2026);
    for (var round = 0; round < 40; round++) {
      final names = _randomNames(random, 10);
      final paid = [
        for (var e = 0; e < 5 + random.nextInt(10); e++)
          (names[random.nextInt(10)], 1 + random.nextInt(30000)),
      ];
      final watch = Stopwatch()..start();
      settle(membersOf(names), expensesOf(paid));
      watch.stop();
      expect(watch.elapsedMilliseconds, lessThanOrEqualTo(1000));
    }
  });
}

const _pool = [
  'דנה', 'יוסי', 'נועה', 'מוטי', 'אבי', 'בני', 'גיל', 'דוד', 'Zoe', 'Adam', //
  'ben', 'Dan', 'דן', "ג'ני", 'דני2', 'דניאל', 'תום', 'אברהם', 'Eli', '7up',
];

/// The most blocks [values] (which add up to zero) can be split into, each
/// adding up to zero: the first value's block is tried with every subset of
/// the rest.
int _mostZeroSumBlocks(List<int> values) {
  if (values.isEmpty) return 0;
  final first = values.first;
  final rest = values.sublist(1);
  var best = 0;
  for (var mask = 0; mask < 1 << rest.length; mask++) {
    var sum = first;
    final others = <int>[];
    for (var i = 0; i < rest.length; i++) {
      if (mask & (1 << i) != 0) {
        sum += rest[i];
      } else {
        others.add(rest[i]);
      }
    }
    if (sum != 0) continue;
    final blocks = 1 + _mostZeroSumBlocks(others);
    if (blocks > best) best = blocks;
  }
  return best;
}

List<String> _randomNames(Random random, int size) =>
    ([..._pool]..shuffle(random)).take(size).toList();

void _expectSettles(Map<String, Tenths> balances, List<Transfer> transfers) {
  final left = {for (final e in balances.entries) e.key: e.value.value};
  for (final t in transfers) {
    expect(t.amount.value, greaterThan(0));
    expect(balances[t.debtorId]!.value, lessThan(0));
    expect(balances[t.receiverId]!.value, greaterThan(0));
    left[t.debtorId] = left[t.debtorId]! + t.amount.value;
    left[t.receiverId] = left[t.receiverId]! - t.amount.value;
  }
  expect(left.values.every((v) => v == 0), isTrue);
}

/// Every subset of debtor→receiver pairs, smallest first; keeps the forests
/// whose flows settle every Balance with positive amounts, and returns the
/// first such list in (debtor, receiver) name order.
List<(String, String, int)> _oracle(
  List<Member> members,
  Map<String, Tenths> balances,
) {
  final names = {for (final m in members) m.id: m.name};
  int byName(String a, String b) => compareNames(names[a]!, names[b]!);
  final debtors = [
    for (final m in members)
      if (balances[m.id]!.value < 0) m.id,
  ]..sort(byName);
  final receivers = [
    for (final m in members)
      if (balances[m.id]!.value > 0) m.id,
  ]..sort(byName);
  if (debtors.isEmpty) return [];
  final pairs = [
    for (final d in debtors)
      for (final r in receivers) (d, r),
  ];
  for (var size = 1; size <= pairs.length; size++) {
    List<(String, String, int)>? best;
    for (var mask = 1; mask < 1 << pairs.length; mask++) {
      if (_bitCount(mask) != size) continue;
      final chosen = [
        for (var i = 0; i < pairs.length; i++)
          if (mask & (1 << i) != 0) pairs[i],
      ];
      final flows = _forestFlows(chosen, balances);
      if (flows == null) continue;
      // `pairs` is already in name order, so `flows` is too.
      if (best == null || _before(flows, best, byName)) best = flows;
    }
    if (best != null) return best;
  }
  throw StateError('oracle found nothing');
}

bool _before(
  List<(String, String, int)> a,
  List<(String, String, int)> b,
  int Function(String, String) byName,
) {
  for (var i = 0; i < a.length; i++) {
    final d = byName(a[i].$1, b[i].$1);
    if (d != 0) return d < 0;
    final r = byName(a[i].$2, b[i].$2);
    if (r != 0) return r < 0;
  }
  return false;
}

int _bitCount(int v) {
  var c = 0;
  for (var x = v; x != 0; x &= x - 1) {
    c++;
  }
  return c;
}

/// Peels leaves of the chosen pairs; `null` unless they form a forest whose
/// flows are all positive and settle every Balance.
List<(String, String, int)>? _forestFlows(
  List<(String, String)> chosen,
  Map<String, Tenths> balances,
) {
  final rem = {for (final e in balances.entries) e.key: e.value.value};
  final open = List<bool>.filled(chosen.length, true);
  final flows = List<int>.filled(chosen.length, 0);
  var progress = true;
  while (progress) {
    progress = false;
    for (final v in rem.keys.toList()) {
      final incident = [
        for (var k = 0; k < chosen.length; k++)
          if (open[k] && (chosen[k].$1 == v || chosen[k].$2 == v)) k,
      ];
      if (incident.length != 1) continue;
      final k = incident.single;
      final isDebtor = chosen[k].$1 == v;
      final flow = isDebtor ? -rem[v]! : rem[v]!;
      if (flow <= 0) return null;
      final other = isDebtor ? chosen[k].$2 : chosen[k].$1;
      rem[other] = rem[other]! + rem[v]!;
      rem[v] = 0;
      flows[k] = flow;
      open[k] = false;
      progress = true;
    }
  }
  if (open.contains(true)) return null; // a cycle
  if (rem.values.any((v) => v != 0)) return null;
  return [
    for (var k = 0; k < chosen.length; k++)
      (chosen[k].$1, chosen[k].$2, flows[k]),
  ];
}
