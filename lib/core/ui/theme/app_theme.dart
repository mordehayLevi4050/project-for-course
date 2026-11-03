import 'package:flutter/material.dart';

import 'tokens.dart';

/// The light-only app theme built from the DESIGN.md tokens (AD-22).
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.secondaryInk,
    onSecondary: AppColors.surfaceRaised,
    error: AppColors.danger,
    onError: AppColors.onDanger,
    surface: AppColors.surfaceRaised,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkSecondary,
    outline: AppColors.inputBorder,
    outlineVariant: AppColors.divider,
    scrim: AppColors.scrim,
  );

  final textTheme = const TextTheme(
    displayLarge: AppTextStyles.amountEntry,
    displayMedium: AppTextStyles.tripTotal,
    displaySmall: AppTextStyles.transferAmount,
    headlineSmall: AppTextStyles.screenTitle,
    titleLarge: AppTextStyles.screenTitle,
    titleMedium: AppTextStyles.rowTitle,
    titleSmall: AppTextStyles.sectionTitle,
    bodyLarge: AppTextStyles.rowTitle,
    bodyMedium: AppTextStyles.message,
    bodySmall: AppTextStyles.meta,
    labelLarge: AppTextStyles.buttonPrimary,
    labelMedium: AppTextStyles.label,
    labelSmall: AppTextStyles.meta,
  ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

  const pill = StadiumBorder();
  const minButtonSize = Size(AppSizes.minTouchTarget, AppSizes.buttonHeight);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    fontFamily: appFontFamily,
    textTheme: textTheme,
    scaffoldBackgroundColor: AppColors.surfaceBase,
    dividerColor: AppColors.divider,
    // Only the two animations allowed by EXPERIENCE.md exist: no ink
    // ripples. Routes are instant through NoTransitionPage in shell/.
    splashFactory: NoSplash.splashFactory,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        disabledForegroundColor: AppColors.onPrimary,
        minimumSize: minButtonSize,
        shape: pill,
        textStyle: AppTextStyles.buttonPrimary,
        elevation: 0,
        shadowColor: AppColors.primary.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surfaceRaised,
        foregroundColor: AppColors.secondaryInk,
        minimumSize: minButtonSize,
        shape: pill,
        side: const BorderSide(color: AppColors.secondaryBorder, width: 1.5),
        textStyle: AppTextStyles.buttonSecondary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceRaised,
      hintStyle: TextStyle(color: AppColors.inkSecondary),
      errorStyle: AppTextStyles.message,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
        borderSide: BorderSide(color: AppColors.inputBorder, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
        borderSide: BorderSide(color: AppColors.inputBorderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
        borderSide: BorderSide(color: AppColors.danger, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
        borderSide: BorderSide(color: AppColors.danger, width: 2),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceRaised,
      modalBarrierColor: AppColors.scrim,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: TextStyle(color: AppColors.surfaceRaised),
      behavior: SnackBarBehavior.floating,
      shape: StadiumBorder(),
    ),
  );
}
