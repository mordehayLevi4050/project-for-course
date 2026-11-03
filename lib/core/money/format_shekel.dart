import 'tenths.dart';

const String _lri = '\u2066'; // LEFT-TO-RIGHT ISOLATE
const String _pdi = '\u2069'; // POP DIRECTIONAL ISOLATE

/// The only way an amount is displayed (AD-12).
///
/// `₪` before the number, thousands grouped with `,`, no decimal when whole
/// and otherwise exactly one, wrapped in LRI/PDI so it stays an LTR run
/// inside RTL text.
String formatShekel(Tenths amount) {
  final negative = amount.value < 0;
  final abs = negative ? -amount.value : amount.value;
  final whole = _groupThousands(abs ~/ 10);
  final decimal = abs % 10;
  final number = decimal == 0 ? whole : '$whole.$decimal';
  return '$_lri${negative ? '-' : ''}₪$number$_pdi';
}

String _groupThousands(int value) {
  final digits = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
