import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The gradient header block of the Group page and the Summary
/// (`components.header-block`). Pass it as `AppScaffold.header`, which paints
/// the gradient.
///
/// Top to bottom: the [navLabel] line, the [name] with the optional
/// [chipLabel] chip (Group page only), the [total] and the [secondaryLine].
/// The category share stripe arrives with Expenses.
class GroupHeader extends StatelessWidget {
  const GroupHeader({
    super.key,
    required this.navLabel,
    required this.onNav,
    required this.name,
    required this.total,
    required this.secondaryLine,
    this.chipLabel,
    this.onChip,
  });

  final String navLabel;
  final VoidCallback onNav;
  final String name;
  final String total;
  final String secondaryLine;
  final String? chipLabel;
  final VoidCallback? onChip;

  static const TextStyle _onHeader = TextStyle(color: AppColors.onHeader);

  @override
  Widget build(BuildContext context) {
    final chipLabel = this.chipLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s5,
        AppSpacing.s1,
        AppSpacing.s5,
        AppSpacing.headerBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The nav line keeps a 48dp hit area.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onNav,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                child: Text(
                  navLabel,
                  style: AppTextStyles.headerSecondary.merge(_onHeader),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  style: AppTextStyles.screenTitle.merge(_onHeader),
                ),
              ),
              if (chipLabel != null) ...[
                const SizedBox(width: AppSpacing.s1),
                _HeaderChip(label: chipLabel, onTap: onChip),
              ],
            ],
          ),
          Text(total, style: AppTextStyles.tripTotal.merge(_onHeader)),
          Text(
            secondaryLine,
            style: AppTextStyles.headerSecondary.merge(_onHeader),
          ),
        ],
      ),
    );
  }
}

/// The "⚙ ✎" chip: an ink-25% overlay with white text, drawn smaller than
/// 48dp but with a 48dp hit area.
class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

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
          widthFactor: 1,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.badgeOnHeaderSurface,
              borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s2,
                vertical: AppSpacing.s1,
              ),
              child: Text(
                label,
                style: AppTextStyles.rowTitle.copyWith(
                  color: AppColors.onHeader,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
