import '../i18n/message_key.dart';
import '../result/result.dart';
import 'tenths.dart';

/// Keypad parsing and bounds for an Expense amount (FR-11, AD-12).
///
/// The keypad edits a plain text buffer made of digits and at most one `.`.
/// This file is the only place that turns that buffer into [Tenths].

/// The keys of the amount keypad.
enum KeypadKey {
  digit0('0'),
  digit1('1'),
  digit2('2'),
  digit3('3'),
  digit4('4'),
  digit5('5'),
  digit6('6'),
  digit7('7'),
  digit8('8'),
  digit9('9'),
  decimalPoint('.'),
  backspace('');

  const KeypadKey(this.symbol);

  final String symbol;
}

/// Longest integer part the keypad accepts. Anything this long is already far
/// above [Tenths.max], so the cap only keeps the buffer bounded; the bound
/// itself is reported by [parseAmount].
const int _maxIntegerDigits = 9;

/// Returns the buffer after pressing [key] on [buffer].
///
/// A press that would make the buffer invalid (a second `.`, a second digit
/// after the `.`) is ignored and the buffer is returned unchanged.
String pressKeypadKey(String buffer, KeypadKey key) {
  if (key == KeypadKey.backspace) {
    if (buffer.isEmpty) return buffer;
    return buffer.substring(0, buffer.length - 1);
  }
  final dot = buffer.indexOf('.');
  if (key == KeypadKey.decimalPoint) {
    if (dot >= 0) return buffer;
    return buffer.isEmpty ? '0.' : '$buffer.';
  }
  if (dot >= 0) {
    // At most one digit after the decimal point.
    if (buffer.length - dot - 1 >= 1) return buffer;
    return buffer + key.symbol;
  }
  if (buffer == '0') return key.symbol; // no leading zeros
  if (buffer.length >= _maxIntegerDigits) return buffer;
  return buffer + key.symbol;
}

/// Parses a keypad buffer into a valid Expense amount.
///
/// Valid means: digits with at most one `.` and at most one decimal digit,
/// greater than zero and at most [Tenths.max].
Result<Tenths> parseAmount(String buffer) {
  const invalid = Failure<Tenths>(MessageKey.invalidAmount);
  final match = RegExp(r'^(\d+)(?:\.(\d)?)?$').firstMatch(buffer);
  if (match == null) return invalid;
  final whole = int.tryParse(match.group(1)!);
  if (whole == null || match.group(1)!.length > _maxIntegerDigits) {
    return invalid;
  }
  final decimal = match.group(2) == null ? 0 : int.parse(match.group(2)!);
  final amount = Tenths(whole * 10 + decimal);
  if (amount <= Tenths.zero || amount > Tenths.max) return invalid;
  return Ok(amount);
}

/// The keypad buffer that shows [amount], for opening an Expense for editing.
String amountToKeypadBuffer(Tenths amount) {
  final whole = amount.value ~/ 10;
  final decimal = amount.value % 10;
  return decimal == 0 ? '$whole' : '$whole.$decimal';
}
