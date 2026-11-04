/// The Expense time format (FR-12, EXPERIENCE.md › Voice and Tone), in the
/// device's local time.
///
/// An Expense first saved today shows only the time, `HH:mm` ("14:32"). One
/// saved on any earlier day, including yesterday, shows only the date,
/// `dd.mm` ("13.12"). [createdAtUtc] and [nowUtc] are UTC epoch millis.
String formatExpenseTime(int createdAtUtc, int nowUtc) {
  final at = DateTime.fromMillisecondsSinceEpoch(createdAtUtc);
  final now = DateTime.fromMillisecondsSinceEpoch(nowUtc);
  final today =
      at.year == now.year && at.month == now.month && at.day == now.day;
  return today
      ? '${_two(at.hour)}:${_two(at.minute)}'
      : '${_two(at.day)}.${_two(at.month)}';
}

String _two(int v) => v.toString().padLeft(2, '0');
