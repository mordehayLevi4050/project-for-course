import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'motion.dart';

/// Shows a bottom sheet (`components.bottom-sheet`): white, `rounded.xl` top
/// corners, a grab handle, over the scrim. It slides up and down through
/// [AppAnimation.sheetSlide], so it is instant when "Remove animations" is on.
/// It is never a centered dialog.
///
/// Resolves to the value the sheet pops with, or `null` when it is dismissed
/// (scrim, system back, drag down, or a plain `Navigator.pop`).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final duration = appAnimationDuration(context, AppAnimation.sheetSlide);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceRaised,
    barrierColor: AppColors.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
    ),
    sheetAnimationStyle: AnimationStyle(
      duration: duration,
      reverseDuration: duration,
    ),
    builder: (context) => Padding(
      // Keeps a text field in the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(top: false, child: builder(context)),
    ),
  );
}

/// The anatomy of a sheet: the [title], an optional [body], an optional
/// [warning] strip (on `badge-active-surface`), then a button row with the [primary] on the start side (about two thirds wide) and the
/// [secondary] beside it.
class AppSheetLayout extends StatelessWidget {
  const AppSheetLayout({
    super.key,
    required this.title,
    this.body,
    this.warning,
    required this.primary,
    required this.secondary,
  });

  final String title;
  final Widget? body;

  /// A warning shown in a strip under the body, such as "הקבוצה '…' תפסיק
  /// להיות הקבוצה הפעילה".
  final String? warning;
  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    final warning = this.warning;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        0,
        AppSpacing.marginMobile,
        AppSpacing.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.screenTitle.copyWith(color: AppColors.ink),
          ),
          if (body != null) ...[const SizedBox(height: AppSpacing.s3), body],
          if (warning != null) ...[
            const SizedBox(height: AppSpacing.s3),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.badgeActiveSurface,
                borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s3,
                  vertical: AppSpacing.s2,
                ),
                child: Text(
                  warning,
                  style: AppTextStyles.message.copyWith(
                    color: AppColors.badgeActiveInk,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s5),
          Row(
            children: [
              Expanded(flex: 2, child: primary),
              const SizedBox(width: AppSpacing.s2),
              Expanded(child: secondary),
            ],
          ),
        ],
      ),
    );
  }
}
