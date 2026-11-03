import 'package:flutter/material.dart';

import '../../i18n/message_key.dart';
import '../theme/tokens.dart';

/// The 56dp gradient top bar of the full-screen forms (Add/Edit expense,
/// Create group). Pass it as `AppScaffold.header`, which paints the gradient.
///
/// The ✕ close sits on the start side when [onClose] is given; the [title] is
/// centered.
class CompactTopBar extends StatelessWidget {
  const CompactTopBar({super.key, required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  static final TextStyle _style = AppTextStyles.screenTitle.copyWith(
    color: AppColors.onHeader,
  );

  @override
  Widget build(BuildContext context) {
    final onClose = this.onClose;
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: SizedBox.square(
                  dimension: AppSizes.minTouchTarget,
                  child: Center(
                    child: Text(MessageKey.close.text, style: _style),
                  ),
                ),
              )
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
