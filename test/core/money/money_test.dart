import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/i18n/message_key.dart';
import 'package:groupay/core/money/amount_input.dart';
import 'package:groupay/core/money/format_shekel.dart';
import 'package:groupay/core/money/tenths.dart';
import 'package:groupay/core/result/result.dart';

String ltr(String s) => '\u2066$s\u2069';

String press(String buffer, String keys) {
  var out = buffer;
  for (final k in keys.split('')) {
    final key = switch (k) {
      '.' => KeypadKey.decimalPoint,
      '<' => KeypadKey.backspace,
      _ => KeypadKey.values[int.parse(k)],
    };
    out = pressKeypadKey(out, key);
  }
  return out;
}

void main() {
  group('Tenths', () {
    test('arithmetic and comparison stay in integer tenths', () {
      const a = Tenths(125);
      const b = Tenths(5);
      expect((a + b).value, 130);
      expect((a - b).value, 120);
      expect((-a).value, -125);
      expect(a > b, isTrue);
      expect(a >= a, isTrue);
      expect(b < a, isTrue);
      expect(b <= b, isTrue);
      expect(Tenths.max.value, 10000000);
      expect(Tenths.zero.value, 0);
    });

    test('isWhole', () {
      expect(const Tenths(120).isWhole, isTrue);
      expect(const Tenths(125).isWhole, isFalse);
    });
  });

  group('formatShekel', () {
    test('matrix rows', () {
      expect(formatShekel(const Tenths(0)), ltr('₪0'));
      expect(formatShekel(const Tenths(120)), ltr('₪12'));
      expect(formatShekel(const Tenths(125)), ltr('₪12.5'));
      expect(formatShekel(const Tenths(12345678)), ltr('₪1,234,567.8'));
    });

    test('groups thousands and never shows two decimals', () {
      expect(formatShekel(const Tenths(12500)), ltr('₪1,250'));
      expect(formatShekel(const Tenths(874)), ltr('₪87.4'));
      expect(formatShekel(const Tenths(1)), ltr('₪0.1'));
      expect(formatShekel(const Tenths(10000000)), ltr('₪1,000,000'));
      expect(formatShekel(const Tenths(9990)), ltr('₪999'));
    });

    test('a negative amount keeps its sign inside the LTR run', () {
      expect(formatShekel(const Tenths(-55)), ltr('-₪5.5'));
    });
  });

  group('parseAmount', () {
    test('valid amounts', () {
      expect(parseAmount('12'), const Ok(Tenths(120)));
      expect(parseAmount('12.5'), const Ok(Tenths(125)));
      expect(parseAmount('12.'), const Ok(Tenths(120)));
      expect(parseAmount('0.1'), const Ok(Tenths(1)));
      expect(parseAmount('1000000'), const Ok(Tenths(10000000)));
      expect(parseAmount('1000000.0'), const Ok(Tenths(10000000)));
    });

    test('invalid amounts are Failure(invalidAmount)', () {
      for (final s in [
        '',
        '0',
        '0.0',
        '-5',
        '1000000.1',
        '2000000',
        '100.01',
        '1.2.3',
        '.5',
        'abc',
        '12,5',
        '99999999999999999999999',
      ]) {
        expect(
          parseAmount(s),
          const Failure<Tenths>(MessageKey.invalidAmount),
          reason: s,
        );
      }
    });
  });

  group('pressKeypadKey', () {
    test('digits append, no leading zeros', () {
      expect(press('', '123'), '123');
      expect(press('', '05'), '5');
      expect(press('', '00'), '0');
    });

    test('a single decimal point, and at most one decimal digit', () {
      expect(press('', '.'), '0.');
      expect(press('', '100.1'), '100.1');
      expect(press('', '100.01'), '100.0');
      expect(press('', '100.12'), '100.1');
      expect(press('', '1..2'), '1.2');
    });

    test('backspace removes the last character and is safe when empty', () {
      expect(press('', '12.5<'), '12.');
      expect(press('', '12.5<<'), '12');
      expect(press('', '<'), '');
    });

    test('the integer part is bounded', () {
      expect(press('', '1234567890123'), '123456789');
    });
  });

  test('amountToKeypadBuffer round-trips through parseAmount', () {
    for (final v in [1, 10, 125, 9990, 10000000]) {
      final buffer = amountToKeypadBuffer(Tenths(v));
      expect(parseAmount(buffer), Ok(Tenths(v)), reason: buffer);
    }
    expect(amountToKeypadBuffer(const Tenths(120)), '12');
    expect(amountToKeypadBuffer(const Tenths(125)), '12.5');
  });
}
