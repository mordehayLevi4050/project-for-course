import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/money/format_shekel.dart';
import '../../../core/policy/group_rules.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/archive_note.dart';
import '../../../core/ui/widgets/bottom_fade.dart';
import '../../../core/ui/widgets/category_stripe.dart';
import '../../../core/ui/widgets/group_header.dart';
import '../../expenses/domain/category.dart';
import '../../expenses/domain/expense.dart';
import '../../groups/app/group_providers.dart';
import '../../groups/domain/member.dart';
import '../app/settle_up_providers.dart';
import '../domain/settlement.dart';
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
/// Read-only mode comes from `isGroupMutable` on the loaded Group, never
/// from the route: an Archived group's Summary shows the badge "🗂 בארכיון"
/// and the archive note under the cards, and "→ חזרה" returns to the
/// archived Group page.
///
/// At the default font the header and the title stay fixed and the card
/// list takes only its content height; when the cards are taller than the
/// remaining space (often with 7–10 Members, but also with long wrapped
/// names at fewer) only they scroll, and the archive note follows the last
/// card or stays pinned below the scroll area. Above the default font the
/// title, cards and note scroll together under the fixed header. Either way
/// the 56dp bottom fade shows only while more content is below.
class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final view = ref.watch(settlementProvider(groupId)).value;
    final settlement = view?.settlement;
    final members = view?.snapshot.members ?? const <Member>[];
    final expenses = view?.snapshot.expenses ?? const <Expense>[];
    final readOnly =
        group != null &&
        !isGroupMutable((isArchived: group.isArchived)).isAllowed;

    return AppScaffold(
      header: group == null || view == null
          ? null
          : GroupHeader(
              navLabel: MessageKey.summaryNav.text,
              onNav: () => context.go(
                readOnly ? '/archive/group/$groupId' : '/group/$groupId',
              ),
              badgeLabel: readOnly ? MessageKey.archivedBadge.text : null,
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
          : _SummaryBody(
              settlement: settlement,
              members: members,
              readOnly: readOnly,
            ),
    );
  }
}

/// The Summary below the header: "מי מעביר למי", the cards (or a note in
/// their place) and, when [readOnly], the archive note under them.
class _SummaryBody extends StatelessWidget {
  const _SummaryBody({
    required this.settlement,
    required this.members,
    required this.readOnly,
  });

  final Settlement? settlement;
  final List<Member> members;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final settlement = this.settlement;
    final title = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.s1,
        bottom: AppSpacing.s2,
      ),
      child: Text(
        MessageKey.transfersTitle.text,
        style: AppTextStyles.sectionTitle.copyWith(color: AppColors.ink),
      ),
    );
    final cards = <Widget>[
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
    ];
    final note = readOnly
        ? ArchiveNote(MessageKey.archiveSummaryNote.text)
        : null;

    // Above the default font the whole body scrolls under the fixed header
    // (EXPERIENCE.md › Accessibility Floor), so nothing is clipped at 1.5.
    final scaled = MediaQuery.textScalerOf(context).scale(_scaleProbe);
    if (scaled > _scaleProbe + _scaleTolerance) {
      return _FadingScroll(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.s5,
            AppSpacing.marginMobile,
            AppSpacing.s4,
          ),
          children: [
            title,
            ...cards,
            if (note != null) ...[
              const SizedBox(height: AppSpacing.s3),
              note,
            ],
          ],
        ),
      );
    }

    // The default font: the title stays fixed and only the cards scroll,
    // with the archive note pinned under them so it stays in view.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.s5,
            AppSpacing.marginMobile,
            0,
          ),
          child: title,
        ),
        // Only the content height, up to the remaining space, so the note
        // follows the last card.
        Flexible(
          child: _FadingScroll(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                0,
                AppSpacing.marginMobile,
                note == null ? AppSpacing.s4 : AppSpacing.s3,
              ),
              children: cards,
            ),
          ),
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              0,
              AppSpacing.marginMobile,
              AppSpacing.s4,
            ),
            child: note,
          ),
      ],
    );
  }
}

/// The font size used to tell the default text scale from a larger one.
final double _scaleProbe = AppTextStyles.rowTitle.fontSize!;

/// Rounding slack when comparing a scaled size with [_scaleProbe].
const double _scaleTolerance = 0.01;

/// A scrolling [child] with the 56dp [BottomFade] over its bottom edge,
/// shown only while more content is below (`extentAfter > 0`): it is gone
/// at the scroll end and never shows when nothing scrolls.
class _FadingScroll extends StatefulWidget {
  const _FadingScroll({required this.child});

  final Widget child;

  @override
  State<_FadingScroll> createState() => _FadingScrollState();
}

class _FadingScrollState extends State<_FadingScroll> {
  bool _moreBelow = false;

  bool _onNotification(Notification notification) {
    final ScrollMetrics metrics;
    switch (notification) {
      case ScrollMetricsNotification(depth: 0):
        metrics = notification.metrics;
      case ScrollNotification(depth: 0):
        metrics = notification.metrics;
      default:
        return false;
    }
    final moreBelow = metrics.extentAfter > 0;
    if (moreBelow != _moreBelow) setState(() => _moreBelow = moreBelow);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<Notification>(
      onNotification: _onNotification,
      child: Stack(
        children: [
          // Not positioned, so a shrink-wrapped list sizes the stack.
          widget.child,
          if (_moreBelow) BottomFade.positioned(),
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
