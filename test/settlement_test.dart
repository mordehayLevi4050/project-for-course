import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/logic/money.dart';
import 'package:groupay/logic/settlement.dart';
import 'package:groupay/models/expense.dart';
import 'package:groupay/models/group.dart';
import 'package:groupay/models/member.dart';

Group _group(List<String> names, Map<String, List<int>> paidShekels) {
  final members = [for (final n in names) Member(id: n, name: n)];
  var i = 0;
  final expenses = [
    for (final entry in paidShekels.entries)
      for (final amount in entry.value)
        Expense(
          id: 'e${i++}',
          payerId: entry.key,
          amountAgorot: amount,
          title: 'x',
          createdAt: DateTime(2026),
        ),
  ];
  return Group(id: 'g', name: 'g', createdAt: DateTime(2026), members: members, expenses: expenses);
}

void main() {
  group('Settlement', () {
    test('example from the plan: 300 + 60 split by three', () {
      final s = Settlement.of(_group(['dani', 'roni', 'maya'], {
        'dani': [30000],
        'roni': [6000],
      }));
      expect(s.totalAgorot, 36000);
      expect(s.shares.values, everyElement(12000));
      expect(s.balances, {'dani': 18000, 'roni': -6000, 'maya': -12000});
      expect(s.transfers, unorderedEquals(const [
        Transfer('maya', 'dani', 12000),
        Transfer('roni', 'dani', 6000),
      ]));
    });

    test('leftover agorot are spread so shares sum to the total', () {
      final s = Settlement.of(_group(['a', 'b', 'c'], {'a': [10000]}));
      expect(s.shares.values.reduce((x, y) => x + y), 10000);
      expect(s.shares, {'a': 3334, 'b': 3333, 'c': 3333});
      expect(s.balances.values.reduce((x, y) => x + y), 0);
    });

    test('everyone paid the same: no transfers', () {
      final s = Settlement.of(_group(['a', 'b'], {'a': [5000], 'b': [5000]}));
      expect(s.transfers, isEmpty);
    });

    test('member who paid nothing owes their share', () {
      final s = Settlement.of(_group(['a', 'b', 'c', 'd'], {
        'a': [10000],
        'b': [10000],
        'c': [4000],
      }));
      // Total 240, share 60 each: d owes 60, c owes 20, a and b get 40 each.
      expect(s.balances, {'a': 4000, 'b': 4000, 'c': -2000, 'd': -6000});
      final received = <String, int>{};
      for (final t in s.transfers) {
        received[t.toId] = (received[t.toId] ?? 0) + t.amountAgorot;
      }
      expect(received, {'a': 4000, 'b': 4000});
      expect(s.transfers.length, lessThanOrEqualTo(3));
    });

    test('no members: empty settlement', () {
      final s = Settlement.of(_group([], {}));
      expect(s.transfers, isEmpty);
      expect(s.balances, isEmpty);
    });
  });

  group('parseShekels', () {
    test('valid inputs', () {
      expect(parseShekels('120'), 12000);
      expect(parseShekels('120.5'), 12050);
      expect(parseShekels('120,05'), 12005);
      expect(parseShekels(' 7. '), 700);
    });

    test('invalid inputs', () {
      expect(parseShekels(''), isNull);
      expect(parseShekels('0'), isNull);
      expect(parseShekels('1.234'), isNull);
      expect(parseShekels('abc'), isNull);
      expect(parseShekels('-5'), isNull);
    });
  });
}
