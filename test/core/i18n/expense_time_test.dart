import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/i18n/expense_time.dart';

int local(int y, int m, int d, [int h = 0, int min = 0]) =>
    DateTime(y, m, d, h, min).toUtc().millisecondsSinceEpoch;

void main() {
  group('formatExpenseTime', () {
    test('today shows HH:mm only', () {
      expect(
        formatExpenseTime(local(2026, 12, 14, 14, 32), local(2026, 12, 14, 18)),
        '14:32',
      );
    });

    test('hours and minutes are zero-padded', () {
      expect(
        formatExpenseTime(local(2026, 12, 14, 7, 5), local(2026, 12, 14, 9)),
        '07:05',
      );
    });

    test('just after midnight today is still today', () {
      expect(
        formatExpenseTime(local(2026, 12, 14, 0, 0), local(2026, 12, 14, 23)),
        '00:00',
      );
    });

    test('yesterday shows dd.mm only', () {
      expect(
        formatExpenseTime(local(2026, 12, 13, 23, 59), local(2026, 12, 14, 0)),
        '13.12',
      );
    });

    test('an earlier month or year shows dd.mm, with no year', () {
      expect(
        formatExpenseTime(local(2026, 3, 5, 10), local(2026, 12, 14)),
        '05.03',
      );
      expect(
        formatExpenseTime(local(2025, 12, 14, 10), local(2026, 12, 14, 10)),
        '14.12',
      );
    });

    test('uses local time, not UTC', () {
      final at = DateTime(2026, 12, 14, 14, 32);
      expect(
        formatExpenseTime(
          at.millisecondsSinceEpoch,
          at.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
        ),
        '14:32',
      );
    });
  });
}
