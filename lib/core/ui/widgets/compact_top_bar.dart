import 'package:flutter/material.dart';

import '../../i18n/message_key.dart';
import '../theme/tokens.dart';
import 'nav_back_label.dart';

/// The 56dp gradient top bar of the full-screen forms (Add/Edit expense,
/// Create group) and Group settings. Pass it as `AppScaffold.header`, which
/// paints the gradient.
///
/// The start side holds the ✕ close when [onClose] is given, or the chevron
/// icon back (semantics label "חזרה") when [onBack] is given (never both);
/// the [title] is centered. The end side holds the optional [action] (Edit expense: the "🗑 מחיקה" chip, see
/// [TopBarDangerChip]), or an empty 48dp slot that keeps the title centered.
class CompactTopBar extends StatelessWidget {
  const CompactTopBar({
    super.key,
    required this.title,
    this.onClose,
    this.onBack,
    this.action,
  }) : assert(onClose == null || onBack == null);

  final String title;
  final VoidCallback? onClose;
  final VoidCallback? onBack;
  final Widget? action;

  static final TextStyle _style = AppTextStyles.screenTitle.copyWith(
    color: AppColors.onHeader,
  );

  @override
  Widget build(BuildContext context) {
    final onClose = this.onClose;
    final onBack = this.onBack;
    const slot = SizedBox.square(dimension: AppSizes.minTouchTarget);
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSizes.compactTopBarHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
        child: Row(
          children: [
            if (onClose != null)
              _BarControl(
                onTap: onClose,
                child: Text(MessageKey.close.text, style: _style),
              )
            else if (onBack != null)
              _BarControl(
                onTap: onBack,
                semanticsLabel: MessageKey.back.text,
                child: NavChevron(size: _style.fontSize, color: _style.color),
              )
            else
              slot,
            Expanded(
              child: Text(title, textAlign: TextAlign.center, style: _style),
            ),
            action ?? slot,
          ],
        ),
      ),
    );
  }
}

/// A glyph or icon control with a 48dp hit area. An icon-only [child] needs
/// a [semanticsLabel].
class _BarControl extends StatelessWidget {
  const _BarControl({
    required this.child,
    required this.onTap,
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final control = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: AppSizes.minTouchTarget,
        child: Center(child: child),
      ),
    );
    final semanticsLabel = this.semanticsLabel;
    if (semanticsLabel == null) return control;
    return Semantics(
      label: semanticsLabel,
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: control,
    );
  }
}

/// The red chip on the end side of a [CompactTopBar] (`colors.danger`), with
/// a 48dp hit area: "🗑 מחיקה" on Edit expense.
class TopBarDangerChip extends StatelessWidget {
  const TopBarDangerChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSizes.minTouchTarget,
          minHeight: AppSizes.minTouchTarget,
        ),
        child: Center(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.all(Radius.circular(AppRadii.full)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s3,
                vertical: AppSpacing.s1,
              ),
              child: Text(
                label,
                style: AppTextStyles.buttonSecondary.copyWith(
                  color: AppColors.onDanger,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
