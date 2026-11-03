import 'package:flutter/material.dart';

import '../../i18n/message_key.dart';
import '../theme/tokens.dart';

/// The 56dp gradient top bar of the full-screen forms (Add/Edit expense,
/// Create group) and Group settings. Pass it as `AppScaffold.header`, which
/// paints the gradient.
///
/// The start side holds the ✕ close when [onClose] is given, or the "→" back
/// when [onBack] is given (never both); the [title] is centered.
class CompactTopBar extends StatelessWidget {
  const CompactTopBar({
    super.key,
    required this.title,
    this.onClose,
    this.onBack,
  }) : assert(onClose == null || onBack == null);

  final String title;
  final VoidCallback? onClose;
  final VoidCallback? onBack;

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
              _BarControl(label: MessageKey.close.text, onTap: onClose)
            else if (onBack != null)
              _BarControl(label: MessageKey.back.text, onTap: onBack)
            else
              slot,
            Expanded(
              child: Text(title, textAlign: TextAlign.center, style: _style),
            ),
            slot,
          ],
        ),
      ),
    );
  }
}

/// A glyph control with a 48dp hit area.
class _BarControl extends StatelessWidget {
  const _BarControl({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: AppSizes.minTouchTarget,
        child: Center(child: Text(label, style: CompactTopBar._style)),
      ),
    );
  }
}
