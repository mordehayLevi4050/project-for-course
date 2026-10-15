import 'package:intl/intl.dart';

/// Formats an amount in agorot as shekels, e.g. 12050 -> 120.50 ₪.
String formatShekels(int agorot) {
  final format = NumberFormat.currency(
    locale: 'he',
    symbol: '₪',
    decimalDigits: agorot % 100 == 0 ? 0 : 2,
  );
  return format.format(agorot / 100);
}

/// Parses user input like "120", "120.5" or "120,50" into agorot.
/// Returns null for anything that is not a positive amount with up to 2 decimals.
int? parseShekels(String input) {
  final match = RegExp(r'^(\d+)(?:[.,](\d{0,2}))?$').firstMatch(input.trim());
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final fraction = int.parse((match.group(2) ?? '').padRight(2, '0'));
  final agorot = whole * 100 + fraction;
  return agorot > 0 ? agorot : null;
}
