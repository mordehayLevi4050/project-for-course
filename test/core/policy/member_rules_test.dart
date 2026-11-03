import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/policy/member_rules.dart';
import 'package:groupay/core/policy/verdict.dart';

void main() {
  group('mayAddMember', () {
    test('9 Members: Allow', () {
      expect(mayAddMember((memberCount: 9)), const Allow());
    });

    test('10 Members: Deny(membersLimit)', () {
      expect(
        mayAddMember((memberCount: 10)),
        const Deny(MessageKey.membersLimit),
      );
    });

    test('0 Members: Allow', () {
      expect(mayAddMember((memberCount: 0)).isAllowed, isTrue);
    });
  });

  group('mayRemoveMember', () {
    test('not a Payer: Allow', () {
      expect(mayRemoveMember((isPayer: false)), const Allow());
    });

    test('a Payer: Deny(memberIsPayer)', () {
      final verdict = mayRemoveMember((isPayer: true));
      expect(verdict, const Deny(MessageKey.memberIsPayer));
      expect(verdict.isAllowed, isFalse);
    });
  });

  group('nextMemberSeq', () {
    test('first Member gets 1', () {
      expect(nextMemberSeq(const []), 1);
    });

    test('MAX + 1, gaps are not filled', () {
      expect(nextMemberSeq(const [1, 2, 5]), 6);
      expect(nextMemberSeq(const [5, 1, 2]), 6);
    });
  });

  group('nextGroupSeq', () {
    test('first Group gets 1', () {
      expect(nextGroupSeq(const []), 1);
    });

    test('MAX + 1, gaps are not filled', () {
      expect(nextGroupSeq(const [1, 2]), 3);
      expect(nextGroupSeq(const [4, 1]), 5);
    });
  });

  test('Verdict equality and toString', () {
    expect(
      const Deny(MessageKey.membersLimit),
      isNot(const Deny(MessageKey.memberIsPayer)),
    );
    expect(const Allow().toString(), 'Allow');
    expect(
      const Deny(MessageKey.membersLimit).toString(),
      'Deny(membersLimit)',
    );
  });
}
