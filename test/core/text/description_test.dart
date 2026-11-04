import 'package:flutter_test/flutter_test.dart';
import 'package:groupay/core/text/description.dart';

void main() {
  test('normalizeDescription trims outer whitespace only', () {
    expect(normalizeDescription('  Umbrella  '), 'Umbrella');
    expect(normalizeDescription('מטרייה גדולה'), 'מטרייה גדולה');
  });

  test('isBlankDescription: empty or whitespace-only', () {
    expect(isBlankDescription(''), isTrue);
    expect(isBlankDescription('  '), isTrue);
    expect(isBlankDescription('\t\n'), isTrue);
    expect(isBlankDescription(' x '), isFalse);
  });
}
