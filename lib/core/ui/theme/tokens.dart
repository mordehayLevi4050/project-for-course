import 'package:flutter/painting.dart';

/// DESIGN.md tokens (AD-22). This is the only place in the app with color,
/// font-size or radius literals. Light theme only.
abstract final class AppColors {
  static const Color headerStart = Color(0xFF0F766E);
  static const Color headerEnd = Color(0xFF0D9488);
  static const Color onHeader = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFEA580C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surfaceBase = Color(0xFFF3F8F7);
  static const Color surfaceRaised = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0B2B28);
  static const Color inkSecondary = Color(0xFF6B7280);
  static const Color inkMuted = Color(0xFF475569);
  static const Color secondaryInk = Color(0xFF0F766E);
  static const Color secondaryBorder = Color(0xFF99CFC9);
  static const Color inputBorder = Color(0xFFCDE3DF);
  static const Color inputBorderFocus = Color(0xFF0D9488);
  static const Color divider = Color(0xFFEEF2F1);
  static const Color currencyMark = Color(0xFF0D9488);
  static const Color transferSurface = Color(0xFFE6F4F1);
  static const Color transferEdge = Color(0xFFEA580C);
  static const Color toggleOff = Color(0xFFCBD5E1);
  static const Color toggleOn = Color(0xFF0F766E);
  static const Color archivedSurface = Color(0xFFE2E8F0);
  static const Color archivedInk = Color(0xFF334155);
  static const Color archivedCardSurface = Color(0xFFF1F3F5);
  static const Color archivedCardInk = Color(0xFF4B5563);
  static const Color badgeActiveSurface = Color(0xFFFFEDD5);
  static const Color badgeActiveInk = Color(0xFF9A3412);

  /// `#0B2B2840`: ink at 25% opacity, for badges and chips on the gradient.
  static const Color badgeOnHeaderSurface = Color(0x400B2B28);
  static const Color danger = Color(0xFFB91C1C);
  static const Color onDanger = Color(0xFFFFFFFF);

  /// `#0B2B2873`: ink at 45% opacity, behind bottom sheets.
  static const Color scrim = Color(0x730B2B28);
  static const Color onMember = Color(0xFFFFFFFF);

  /// Avatar fills, by add order (`memberSeq`), wrapping after 6.
  static const List<Color> members = [
    Color(0xFF1D4ED8),
    Color(0xFF9333EA),
    Color(0xFFC2410C),
    Color(0xFFBE185D),
    Color(0xFF047857),
    Color(0xFFA16207),
  ];

  // Category colors: non-text marks only (stripe, tint, selected tile).
  static const Color categoryFlight = Color(0xFF3B82F6);
  static const Color categoryHotel = Color(0xFF8B5CF6);
  static const Color categoryCar = Color(0xFF14B8A6);
  static const Color categoryFuel = Color(0xFFF59E0B);
  static const Color categoryRestaurant = Color(0xFFEF4444);
  static const Color categoryFoodDrink = Color(0xFF22C55E);
  static const Color categoryAttractions = Color(0xFFEC4899);
  static const Color categoryOther = Color(0xFF64748B);
}

/// The lagoon gradient behind the header block and the compact top bar.
abstract final class AppGradients {
  static const LinearGradient header = LinearGradient(
    // 135°: from the top start corner to the bottom end corner.
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [AppColors.headerStart, AppColors.headerEnd],
  );
}

/// Radii (`rounded.*`).
abstract final class AppRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double full = 9999;
}

/// Spacing scale (`spacing.*`), in dp.
abstract final class AppSpacing {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double listFade = 56;
  static const double marginMobile = 16;
}

/// Component sizes from DESIGN.md `components.*`, in dp. Heights are minimums:
/// they grow with the text scale.
abstract final class AppSizes {
  static const double buttonHeight = 64;
  static const double compactTopBarHeight = 56;
  static const double minTouchTarget = 48;
  static const double avatar = 44;
  static const double avatarSlot = 48;
  static const double textFieldHeight = 52;
}

/// The bundled font family (no runtime font fetching, NFR-8).
const String appFontFamily = 'Heebo';

/// Type scale (`typography.*`). All sizes are logical pixels that follow the
/// system text scale (sp), clamped to 1.5 in `shell/`.
///
/// Heebo is bundled as a variable font, so every style also sets the `wght`
/// axis to its weight.
abstract final class AppTextStyles {
  static const TextStyle tripTotal = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation.weight(800)],
  );
  static const TextStyle amountEntry = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 46,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation.weight(800)],
  );
  static const TextStyle screenTitle = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation.weight(700)],
  );
  static const TextStyle headerSecondary = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation.weight(700)],
  );
  static const TextStyle transferAmount = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation.weight(800)],
  );
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation.weight(700)],
  );
  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation.weight(600)],
  );
  static const TextStyle rowTitle = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation.weight(600)],
  );
  static const TextStyle rowAmount = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation.weight(700)],
  );
  static const TextStyle keypadDigit = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation.weight(600)],
  );
  static const TextStyle avatarInitial = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation.weight(800)],
  );
  static const TextStyle label = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation.weight(600)],
  );
  static const TextStyle meta = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation.weight(400)],
  );
  static const TextStyle message = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation.weight(400)],
  );
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation.weight(700)],
  );
}
