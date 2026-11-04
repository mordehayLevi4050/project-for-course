import 'package:flutter/material.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/money/format_shekel.dart';
import '../../../core/money/tenths.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/group.dart';

/// A Group card of the group list (DESIGN.md › Group card): the name, the
/// Member count and the Trip total on the end side. The Active group gets a
/// 6dp orange start edge and the badge "⭐ פעילה".
class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
    required this.item,
    required this.total,
    required this.onTap,
  });

  final GroupListItem item;

  /// The Trip total, from `GroupTotalsPort`.
  final Tenths total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _CardFrame(
        color: AppColors.surfaceRaised,
        edgeColor: item.isActive ? AppColors.primary : null,
        child: Row(
          children: [
            Expanded(
              child: _NameAndCount(
                item: item,
                nameColor: AppColors.ink,
                countColor: AppColors.inkSecondary,
              ),
            ),
            if (item.isActive) ...[
              const SizedBox(width: AppSpacing.s2),
              const _ActiveBadge(),
            ],
            const SizedBox(width: AppSpacing.s3),
            _Total(total: total, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

/// An archived Group card of the Archive view (DESIGN.md › Archived group
/// card): gray, no colored edge, and a "↩ שחזור" text button on the end
/// side with a 48dp hit area.
class ArchivedGroupCard extends StatelessWidget {
  const ArchivedGroupCard({
    super.key,
    required this.item,
    required this.total,
    required this.onTap,
    required this.onRestore,
  });

  final GroupListItem item;

  /// The Trip total, from `GroupTotalsPort`.
  final Tenths total;
  final VoidCallback onTap;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _CardFrame(
        color: AppColors.archivedCardSurface,
        child: Row(
          children: [
            Expanded(
              child: _NameAndCount(
                item: item,
                nameColor: AppColors.archivedCardInk,
                countColor: AppColors.archivedCardInk,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            _Total(total: total, color: AppColors.archivedCardInk),
            const SizedBox(width: AppSpacing.s2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Kept even while disabled, so a tap on "↩ שחזור" never falls
              // through to the card and opens the page mid-restore.
              onTap: onRestore ?? () {},
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppSizes.minTouchTarget,
                  minHeight: AppSizes.minTouchTarget,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    MessageKey.restore.text,
                    style: AppTextStyles.buttonSecondary.copyWith(
                      color: AppColors.secondaryInk,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rounded card with the card shadow and an optional start-edge stripe.
class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.color, required this.child, this.edgeColor});

  final Color color;
  final Color? edgeColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final edgeColor = this.edgeColor;
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.lg)),
        child: ColoredBox(
          color: color,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (edgeColor != null)
                  SizedBox(
                    width: AppSizes.startEdge,
                    child: ColoredBox(color: edgeColor),
                  ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: AppSizes.cardMinHeight,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s4,
                      vertical: AppSpacing.s3,
                    ),
                    alignment: AlignmentDirectional.centerStart,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NameAndCount extends StatelessWidget {
  const _NameAndCount({
    required this.item,
    required this.nameColor,
    required this.countColor,
  });

  final GroupListItem item;
  final Color nameColor;
  final Color countColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.group.name,
          style: AppTextStyles.rowTitle.copyWith(color: nameColor),
        ),
        Text(
          memberCountText(item.memberCount),
          style: AppTextStyles.meta.copyWith(color: countColor),
        ),
      ],
    );
  }
}

/// "⭐ פעילה" (`badge-active-surface` / `badge-active-ink`).
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.badgeActiveSurface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s2,
          vertical: AppSpacing.s1,
        ),
        child: Text(
          MessageKey.activeBadge.text,
          style: AppTextStyles.label.copyWith(color: AppColors.badgeActiveInk),
        ),
      ),
    );
  }
}

/// The Trip total on the end side of a card, through `formatShekel()`.
class _Total extends StatelessWidget {
  const _Total({required this.total, required this.color});

  final Tenths total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatShekel(total),
      style: AppTextStyles.rowAmount.copyWith(color: color),
    );
  }
}
