import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/text/grapheme_limit_formatter.dart';
import 'package:groupay/core/text/names.dart';

TextEditingValue typed(String text) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: text.length),
);

void main() {
  group('normalizeName / nameKey', () {
    test('outer spaces are trimmed, inner spaces kept', () {
      expect(normalizeName(' Dana '), 'Dana');
      expect(normalizeName('  Dana Levi\t'), 'Dana Levi');
    });

    test('" Dana ", "dana" and "DANA" share one key', () {
      expect(nameKey(' Dana '), nameKey('dana'));
      expect(nameKey('DANA'), nameKey('dana'));
      expect(nameKey(' budapest '), nameKey('Budapest'));
    });

    test('different names have different keys', () {
      expect(nameKey('Dana'), isNot(nameKey('Danna')));
      expect(nameKey('דנה'), isNot(nameKey('דן')));
    });

    test('isBlankName', () {
      expect(isBlankName(''), isTrue);
      expect(isBlankName('   '), isTrue);
      expect(isBlankName(' a '), isFalse);
    });

    test('limits', () {
      expect(maxGroupNameLength, 20);
      expect(maxMemberNameLength, 10);
    });
  });

  group('graphemeLength / truncateGraphemes', () {
    test('an emoji with a skin tone counts as one', () {
      expect(graphemeLength('👍🏽'), 1);
    });

    test('each Hebrew letter with its niqqud counts once', () {
      expect(graphemeLength('שָׁלוֹם'), 4);
    });

    test('plain text', () {
      expect(graphemeLength(''), 0);
      expect(graphemeLength('Dana'), 4);
    });

    test('truncation keeps whole clusters', () {
      expect(truncateGraphemes('שָׁלוֹם', 2), 'שָׁל');
      expect(truncateGraphemes('a👍🏽b', 2), 'a👍🏽');
      expect(truncateGraphemes('abc', 5), 'abc');
    });
  });

  group('GraphemeLimitFormatter', () {
    final formatter = GraphemeLimitFormatter(20);

    test('a 25-character paste into a 20 limit keeps the first 20', () {
      const pasted = 'abcdefghijklmnopqrstuvwxy';
      final out = formatter.formatEditUpdate(typed(''), typed(pasted));
      expect(out.text, 'abcdefghijklmnopqrst');
      expect(out.selection, const TextSelection.collapsed(offset: 20));
    });

    test('a 21st character is blocked', () {
      final full = typed('a' * 20);
      final out = formatter.formatEditUpdate(full, typed('${'a' * 20}b'));
      expect(out, full);
    });

    test('input within the limit passes through', () {
      final next = typed('abc');
      expect(formatter.formatEditUpdate(typed('ab'), next), next);
    });

    test('pasting over a selection in a full field is cut, not blocked', () {
      final full = TextEditingValue(
        text: 'a' * 20,
        selection: const TextSelection(baseOffset: 0, extentOffset: 20),
      );
      final out = formatter.formatEditUpdate(full, typed('b' * 25));
      expect(out.text, 'b' * 20);
    });

    test('counts graphemes, not code units', () {
      final small = GraphemeLimitFormatter(2);
      final out = small.formatEditUpdate(typed(''), typed('👍🏽👍🏽👍🏽'));
      expect(out.text, '👍🏽👍🏽');
    });
  });
}
