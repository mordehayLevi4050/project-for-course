import 'package:flutter/material.dart';

/// Brand colors, a turquoise palette in the spirit of bit.
class GroupayColors {
  static const turquoise = Color(0xFF00B9C6);
  static const mint = Color(0xFF1DD3B0);
  static const deepTeal = Color(0xFF00838F);
  static const background = Color(0xFFF4F7F8);
  static const positive = Color(0xFF2E7D32);
  static const negative = Color(0xFFC62828);
}

ThemeData buildGroupayTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: GroupayColors.turquoise,
    primary: GroupayColors.deepTeal,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GroupayColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: GroupayColors.turquoise,
      foregroundColor: Colors.white,
    ),
  );
}
