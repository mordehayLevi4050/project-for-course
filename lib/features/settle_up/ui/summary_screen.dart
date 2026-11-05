import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/money/format_shekel.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/category_stripe.dart';
import '../../../core/ui/widgets/group_header.dart';
import '../../expenses/domain/category.dart';
import '../../expenses/domain/expense.dart';
import '../../groups/app/group_providers.dart';
import '../app/settle_up_providers.dart';
import 'transfer_card.dart';

/// The Summary (FR-16): the header block (nav "→ חזרה" back to the Group
/// page, the name without the "⚙ ✎" chip, the Trip total, the share line
/// "{n} משתתפים · ₪{share} לאחד" and the category share stripe), then
/// "מי מעביר למי" and one [TransferCard] per Transfer with 8dp gaps, or the
/// fixed settled message in their place.
///
/// No bottom bar, no Balance table and no breakdown. It only reads; every
/// amount comes from the `settle_up` calculation. Below two Members
/// (`maySummarize` denies, reachable only by typing the route) the body
/// shows the fixed two-Members hint instead.
///
/// The body scrolls, so a larger font never overflows; at the default font
/// a Group of up to 6 Members fits without scrolling.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final view = ref.watch(settlementProvider(groupId)).value;
    final settlement = view?.settlement;
    final members = view?.snapshot.members ?? const [];
    final expenses = view?.snapshot.expenses ?? const <Expense>[];

    return AppScaffold(
      header: group == null || view == null
          ? null
          : GroupHeader(
              navLabel: MessageKey.summaryNav.text,
              onNav: () => context.go('/group/$groupId'),
              name: group.name,
              total: formatShekel(tripTotal(expenses)),
              secondaryLine: settlement == null
                  ? memberCountText(members.length)
                  : shareLineText(
                      memberCount: members.length,
                      share: settlement.share,
                    ),
              stripe: CategoryStripe(
                segments: [
                  for (final (category, total) in categoryTotals(expenses))
                    (color: _stripeColor(category), weight: total.value),
                ],
              ),
            ),
      body: view == null
          // Local data only: the first stream event arrives at once.
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.s5,
                AppSpacing.marginMobile,
                AppSpacing.s4,
              ),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.s1,
                    bottom: AppSpacing.s2,
                  ),
                  child: Text(
                    MessageKey.transfersTitle.text,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (settlement == null)
                  _Note(MessageKey.needTwoMembers.text)
                else if (settlement.transfers.isEmpty)
                  _Note(MessageKey.settledUp.text)
                else
                  for (final (i, t) in settlement.transfers.indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.s2),
                    TransferCard(
                      debtor: members.firstWhere((m) => m.id == t.debtorId),
                      receiver: members.firstWhere((m) => m.id == t.receiverId),
                      amount: t.amount,
                    ),
                  ],
              ],
            ),
    );
  }
}

/// A message shown in place of the Transfer cards.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.s1,
        top: AppSpacing.s2,
      ),
      child: Text(
        text,
        style: AppTextStyles.rowTitle.copyWith(color: AppColors.inkMuted),
      ),
    );
  }
}

/// The share stripe color of each Category: the same `AppColors` tokens as
/// the Group page's `categoryColor()` (DESIGN.md › Colors). Repeated here
/// because a feature's `ui/` may not import another feature's `ui/`; the
/// exhaustive switch fails to compile if a Category is added.
Color _stripeColor(Category category) => switch (category) {
  Category.flight => AppColors.categoryFlight,
  Category.hotel => AppColors.categoryHotel,
  Category.car => AppColors.categoryCar,
  Category.fuel => AppColors.categoryFuel,
  Category.restaurant => AppColors.categoryRestaurant,
  Category.foodDrink => AppColors.categoryFoodDrink,
  Category.attractions => AppColors.categoryAttractions,
  Category.other => AppColors.categoryOther,
};
