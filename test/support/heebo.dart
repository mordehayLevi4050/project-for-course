import 'package:flutter/services.dart';

bool _loaded = false;

/// Loads the bundled Heebo font into the test engine, so layout runs with
/// the real glyph metrics instead of the square test font.
Future<void> loadHeebo() async {
  if (_loaded) return;
  final loader = FontLoader('Heebo')
    ..addFont(rootBundle.load('assets/fonts/Heebo-VariableFont_wght.ttf'));
  await loader.load();
  _loaded = true;
}
