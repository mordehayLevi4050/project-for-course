import 'package:characters/characters.dart';

/// Name rules shared by Groups and Members (AD-13). This file is the only
/// place that trims, case-folds or measures a name.

/// Longest Group name, in grapheme clusters (FR-1).
const int maxGroupNameLength = 20;

/// Longest Member name, in grapheme clusters (FR-2).
const int maxMemberNameLength = 10;

/// The name as it is saved and displayed: outer whitespace removed.
String normalizeName(String raw) => raw.trim();

/// The uniqueness key: the normalized name, case-folded.
///
/// Two names collide exactly when their keys are equal. SQL `lower()` and
/// `NOCASE` are never used on names; the key is computed here and stored.
String nameKey(String raw) => normalizeName(raw).toLowerCase();

/// Length in grapheme clusters: an emoji with a skin tone, or a Hebrew letter
/// with its niqqud, counts as one.
int graphemeLength(String text) => text.characters.length;

/// The first [max] grapheme clusters of [text].
String truncateGraphemes(String text, int max) {
  final chars = text.characters;
  return chars.length <= max ? text : chars.take(max).toString();
}

/// Whether [raw] is empty once normalized (FR-1, FR-2: "Name required").
bool isBlankName(String raw) => normalizeName(raw).isEmpty;

/// The name as it is saved: normalized and cut to [maxLength] grapheme
/// clusters, so a repository never stores an over-long name even when the
/// input bypassed the field's formatter.
String normalizeNameWithin(String raw, int maxLength) =>
    normalizeName(truncateGraphemes(normalizeName(raw), maxLength));
