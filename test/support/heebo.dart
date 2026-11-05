import 'package:flutter/services.dart';

bool _loaded = false;

/// Loads the bundled Heebo font into the test engine, so layout runs with
/// the real glyph metrics instead of the square test font. Also loads the
/// bundled MaterialIcons font, so icons such as the nav chevron render.
Future<void> loadHeebo() async {
  if (_loaded) return;
  final heebo = FontLoader('Heebo')
    ..addFont(rootBundle.load('assets/fonts/Heebo-VariableFont_wght.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([heebo.load(), icons.load()]);
  _loaded = true;
}
