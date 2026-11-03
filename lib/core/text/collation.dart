import 'package:characters/characters.dart';

/// The FR-15 alphabetical order of names (AD-13, transfer-calculation.md).
///
/// Names are compared one character (grapheme cluster) at a time, using the
/// cluster's first code point:
/// 1. Hebrew letters in alphabet order, final letters folded to their
///    regular form (ך=כ, ם=מ, ן=נ, ף=פ, ץ=צ);
/// 2. Latin A–Z, ignoring case;
/// 3. digits 0–9;
/// 4. the geresh (׳ or ');
/// 5. any other character, by Unicode value.
///
/// A name that is the start of a longer one sorts first. Names that are still
/// equal are ordered by Unicode value.
int compareNames(String a, String b) {
  final ca = a.characters.iterator;
  final cb = b.characters.iterator;
  while (true) {
    final hasA = ca.moveNext();
    final hasB = cb.moveNext();
    if (!hasA || !hasB) {
      if (hasA != hasB) return hasA ? 1 : -1; // a prefix sorts first
      break;
    }
    final byKey = _sortKey(ca.current.runes.first)
        .compareTo(_sortKey(cb.current.runes.first));
    if (byKey != 0) return byKey;
  }
  return _compareCodePoints(a, b);
}

const int _classHebrew = 0;
const int _classLatin = 1;
const int _classDigit = 2;
const int _classGeresh = 3;
const int _classOther = 4;

/// Packs (class, rank) into one int so a single comparison orders both.
int _sortKey(int rune) => _class(rune) * 0x200000 + _rank(rune);

int _class(int rune) {
  if (_isHebrewLetter(rune)) return _classHebrew;
  if (_isLatinLetter(rune)) return _classLatin;
  if (rune >= 0x30 && rune <= 0x39) return _classDigit;
  if (rune == 0x05F3 || rune == 0x27) return _classGeresh;
  return _classOther;
}

int _rank(int rune) {
  if (_isHebrewLetter(rune)) return _finalToRegular[rune] ?? rune;
  if (_isLatinLetter(rune)) return rune | 0x20; // lower case
  if (rune == 0x05F3 || rune == 0x27) return 0; // both gereshes are equal
  return rune;
}

bool _isHebrewLetter(int rune) => rune >= 0x05D0 && rune <= 0x05EA;

bool _isLatinLetter(int rune) =>
    (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);

/// In Unicode each final letter sits just before its regular form, so
/// folding gives alphabet order directly.
const Map<int, int> _finalToRegular = {
  0x05DA: 0x05DB, // ך → כ
  0x05DD: 0x05DE, // ם → מ
  0x05DF: 0x05E0, // ן → נ
  0x05E3: 0x05E4, // ף → פ
  0x05E5: 0x05E6, // ץ → צ
};

int _compareCodePoints(String a, String b) {
  final ra = a.runes.iterator;
  final rb = b.runes.iterator;
  while (true) {
    final hasA = ra.moveNext();
    final hasB = rb.moveNext();
    if (!hasA || !hasB) return hasA == hasB ? 0 : (hasA ? 1 : -1);
    final diff = ra.current - rb.current;
    if (diff != 0) return diff < 0 ? -1 : 1;
  }
}
