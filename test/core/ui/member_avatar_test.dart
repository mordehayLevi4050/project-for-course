import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/ui/theme/tokens.dart';
import 'package:groupay/core/ui/widgets/member_avatar.dart';

void main() {
  group('memberColorIndex', () {
    test('follows memberSeq and wraps after 6', () {
      expect(
        [for (var seq = 1; seq <= 10; seq++) memberColorIndex(seq)],
        [0, 1, 2, 3, 4, 5, 0, 1, 2, 3],
      );
    });

    test('the 7th Member gets color index 0', () {
      expect(memberColorIndex(7), 0);
    });
  });

  group('avatarLabel', () {
    test('a shared first word shows the full names', () {
      const names = ['Dana Levi', 'Dana Cohen', 'Yossi'];
      expect([for (final n in names) avatarLabel(n, names)], names);
    });

    test('a unique first word shows only that word', () {
      const names = ['Dana Levi', 'Yossi Cohen'];
      expect(avatarLabel('Dana Levi', names), 'Dana');
      expect(avatarLabel('Yossi Cohen', names), 'Yossi');
    });

    test('first words are compared ignoring case', () {
      const names = ['dana Levi', 'Dana'];
      expect(avatarLabel('dana Levi', names), 'dana Levi');
      expect(avatarLabel('Dana', names), 'Dana');
    });

    test('works with or without the name itself in the list', () {
      expect(avatarLabel('Dana Levi', const ['Yossi']), 'Dana');
      expect(avatarLabel('Dana Levi', const ['Dana Levi']), 'Dana');
      expect(avatarLabel('Dana Levi', const ['Dana Cohen']), 'Dana Levi');
    });

    test('Hebrew names', () {
      const names = ['דנה לוי', 'דנה כהן', 'מוטי'];
      expect(avatarLabel('דנה לוי', names), 'דנה לוי');
      expect(avatarLabel('מוטי', names), 'מוטי');
    });
  });

  testWidgets('MemberAvatar shows the initial, the label and the color', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: MemberAvatar(
            name: 'Alexandrin',
            memberSeq: 8,
            label: 'Alexandrin',
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Alexandrin'), findsOneWidget);
    final circle = tester.widget<Container>(
      find.ancestor(of: find.text('A'), matching: find.byType(Container)).first,
    );
    expect((circle.decoration! as BoxDecoration).color, AppColors.members[1]);
    // The label is never truncated: no ellipsis, no line limit.
    final label = tester.widget<Text>(find.text('Alexandrin'));
    expect(label.maxLines, isNull);
    expect(label.overflow, isNot(TextOverflow.ellipsis));
  });
}
