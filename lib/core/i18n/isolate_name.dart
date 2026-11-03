const String _fsi = '\u2068'; // FIRST STRONG ISOLATE
const String _pdi = '\u2069'; // POP DIRECTIONAL ISOLATE

/// The only way a user-entered name enters a sentence (AD-14).
///
/// The name is wrapped in FSI/PDI so a Latin or mixed name never reorders the
/// surrounding RTL line. [prefix] is a Hebrew prefix letter attached to the
/// name, such as "מ" or "ל". When the name does not start with a Hebrew
/// letter, a hyphen joins them: "מ-Dan" but "מדנה".
String isolateName(String name, {String prefix = ''}) {
  final joiner = prefix.isNotEmpty && !_startsWithHebrewLetter(name) ? '-' : '';
  return '$prefix$joiner$_fsi$name$_pdi';
}

bool _startsWithHebrewLetter(String name) {
  if (name.isEmpty) return false;
  final first = name.runes.first;
  return first >= 0x05D0 && first <= 0x05EA;
}
