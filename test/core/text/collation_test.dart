import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/text/collation.dart';

List<String> sorted(List<String> names) => [...names]..sort(compareNames);

void main() {
  test('class order: Hebrew, Latin, digits, geresh, then Unicode', () {
    expect(sorted(['😀', "'a", '7', 'Zoe', 'דנה', '׳b', 'אבי', 'adam', 'Ω']), [
      'אבי',
      'דנה',
      'adam',
      'Zoe',
      '7',
      "'a",
      '׳b',
      'Ω',
      '😀',
    ]);
  });

  test('Hebrew letters in alphabet order', () {
    expect(sorted(['תמר', 'שי', 'בני', 'אור', 'יעל']), [
      'אור',
      'בני',
      'יעל',
      'שי',
      'תמר',
    ]);
  });

  test('Latin ignores case, Unicode value breaks the tie', () {
    expect(sorted(['bob', 'Alice', 'alice', 'Bob', 'carl']), [
      'Alice',
      'alice',
      'Bob',
      'bob',
      'carl',
    ]);
  });

  test('final letters fold to their regular form', () {
    // ך = כ, so the next letter decides: א before ב.
    expect(compareNames('ךא', 'כב'), lessThan(0));
    expect(compareNames('כב', 'ךא'), greaterThan(0));
    // Equal after folding: Unicode breaks the tie (ך U+05DA < כ U+05DB).
    expect(compareNames('ך', 'כ'), lessThan(0));
    for (final (fin, reg) in [
      ('ך', 'כ'),
      ('ם', 'מ'),
      ('ן', 'נ'),
      ('ף', 'פ'),
      ('ץ', 'צ'),
    ]) {
      // A final letter sorts with its regular form: after the letter before
      // it in the alphabet... and before the one after it.
      expect(compareNames('$finב', '$regא'), greaterThan(0), reason: fin);
      expect(compareNames('$finא', '$regב'), lessThan(0), reason: fin);
    }
    // ם folds to מ, which comes after ל.
    expect(compareNames('ם', 'ל'), greaterThan(0));
  });

  test('a prefix sorts first', () {
    expect(compareNames('דן', 'דנה'), lessThan(0));
    expect(compareNames('Alexandrin', 'Alexandrina'), lessThan(0));
    expect(compareNames('Alexandrina', 'Alexandrin'), greaterThan(0));
    expect(compareNames('', 'a'), lessThan(0));
  });

  test('both gereshes rank together; Unicode breaks the tie', () {
    expect(compareNames("ג'א", 'ג׳ב'), lessThan(0));
    expect(compareNames("'", '׳'), lessThan(0));
  });

  test('digits in numeric-character order', () {
    expect(sorted(['9', '10', '2']), ['10', '2', '9']);
  });

  test('Hebrew with niqqud sorts by its letters', () {
    // Same letters: the Unicode tie-break puts the niqqud (U+05B8) before
    // the bare letter ל (U+05DC).
    expect(compareNames('שָׁלוֹם', 'שלום'), lessThan(0));
    expect(compareNames('שָׁלוֹם', 'תמר'), lessThan(0));
  });

  test('identical names compare equal; the order is antisymmetric', () {
    expect(compareNames('Dana', 'Dana'), 0);
    const names = ['דנה', 'Dana', 'dana', '7', "'", '😀', 'ךא', 'כב'];
    for (final a in names) {
      for (final b in names) {
        expect(compareNames(a, b).sign, -compareNames(b, a).sign);
      }
    }
  });
}
