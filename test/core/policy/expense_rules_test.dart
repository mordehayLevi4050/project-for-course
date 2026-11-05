import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/policy/expense_rules.dart';
import 'package:groupay/core/policy/sequence.dart';
import 'package:groupay/core/policy/verdict.dart';

void main() {
  group('mayRecordExpense', () {
    test('0 or 1 Members: Deny(needTwoMembers)', () {
      expect(
        mayRecordExpense((memberCount: 0)),
        const Deny(MessageKey.needTwoMembers),
      );
      expect(
        mayRecordExpense((memberCount: 1)),
        const Deny(MessageKey.needTwoMembers),
      );
    });

    test('2 or more Members: Allow', () {
      expect(mayRecordExpense((memberCount: 2)), const Allow());
      expect(mayRecordExpense((memberCount: 10)), const Allow());
    });
  });

  group('defaultPayer', () {
    test('the last Payer while still a Member', () {
      expect(
        defaultPayer(lastPayerId: 'motty', memberIdsBySeq: ['dana', 'motty']),
        'motty',
      );
    });

    test('no Expenses: the earliest-added Member', () {
      expect(
        defaultPayer(lastPayerId: null, memberIdsBySeq: ['motty', 'dana']),
        'motty',
      );
    });

    test('a last Payer who is gone falls back to the earliest Member', () {
      expect(
        defaultPayer(lastPayerId: 'yossi', memberIdsBySeq: ['dana', 'motty']),
        'dana',
      );
    });

    test('no Members: null', () {
      expect(defaultPayer(lastPayerId: null, memberIdsBySeq: []), isNull);
    });
  });

  group('mayModifyExpense', () {
    test('an Archived group: Deny(groupArchived)', () {
      expect(
        mayModifyExpense((isArchived: true)),
        const Deny(MessageKey.groupArchived),
      );
    });

    test('a Group that is not archived: Allow', () {
      expect(mayModifyExpense((isArchived: false)), const Allow());
    });
  });

  group('nextSaveSeq', () {
    test('the first Expense gets 1', () {
      expect(nextSaveSeq([]), 1);
    });

    test('MAX + 1, whatever the order or gaps', () {
      expect(nextSaveSeq([3, 1, 2]), 4);
      expect(nextSaveSeq([1, 7]), 8);
    });
  });

  group('maxPlusOne', () {
    test('1 when empty, otherwise MAX + 1', () {
      expect(maxPlusOne([]), 1);
      expect(maxPlusOne([5]), 6);
      expect(maxPlusOne([2, 9, 4]), 10);
    });
  });
}
