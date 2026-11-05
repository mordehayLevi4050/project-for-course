import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/money/format_shekel.dart';
import '../../../core/policy/expense_rules.dart';
import '../../../core/policy/group_rules.dart';
import '../../../core/result/result.dart';
import '../../../core/time/clock_provider.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/archive_note.dart';
import '../../../core/ui/widgets/bottom_fade.dart';
import '../../../core/ui/widgets/category_stripe.dart';
import '../../../core/ui/widgets/delete_sheet.dart';
import '../../../core/ui/widgets/group_header.dart';
import '../../../core/ui/widgets/snackbar.dart';
import '../../groups/app/group_providers.dart';
import '../app/expense_providers.dart';
import '../domain/expense.dart';
import 'category_style.dart';
import 'expense_list.dart';

/// The Group page (FR-6, FR-10, FR-12): the header block (nav, name with the
/// "⚙ ✎" chip, Trip total, "{n} משתתפים · {m} הוצאות" and the category share
/// stripe), the Expense list overlapping the header by 16dp and fading over
/// 56dp above the bottom bar, "+ הוספת הוצאה" and "סיכום".
///
/// "+ הוספת הוצאה" and "סיכום" are disabled below two Members, with the
/// fixed hint above the bar (the repository refuses the insert too).
///
/// Read-only mode comes from `isGroupMutable`, never from the route. An
/// Archived group shows the nav "→ ארכיון", the badge "🗂 בארכיון", no chip,
/// the list, total and stripe as usual, and the archive note above a bottom
/// bar whose primary is "↩ שחזור מהארכיון".
///
/// A tap on an Expense row opens Edit expense; a long-press opens the Delete
/// sheet, and "מחיקה" deletes it and shows the snackbar "ההוצאה נמחקה". In
/// an Archived group rows are view-only.
class GroupPage extends ConsumerWidget {
  const GroupPage({super.key, required this.groupId});

  final String groupId;

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(restoreGroupProvider.notifier)
        .submit(id: groupId);
    if (!context.mounted) return;
    // Back from the restored page leads to the group list.
    if (result is Ok) context.go('/group/$groupId');
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
    String payerName,
  ) async {
    final confirmed = await showDeleteSheet(
      context,
      line: expenseLineText(expense, payerName),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(deleteExpenseProvider.notifier)
        .submit(id: expense.id);
    if (result is Ok) showAppSnackbar(MessageKey.expenseDeleted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final members = ref.watch(membersProvider(groupId)).value ?? const [];
    final expenses = ref.watch(expensesProvider(groupId)).value;
    final readOnly =
        group != null &&
        !isGroupMutable((isArchived: group.isArchived)).isAllowed;
    final canRecord = mayRecordExpense((memberCount: members.length)).isAllowed;
    final canSummarize = maySummarize((memberCount: members.length)).isAllowed;
    // Keeps the notifier (and its in-flight guard) alive.
    final restoring = ref.watch(restoreGroupProvider);
    ref.watch(deleteExpenseProvider);
    final payerNames = {for (final m in members) m.id: m.name};
    final shown = expenses ?? const <Expense>[];

    return AppScaffold(
      header: group == null
          ? null
          : GroupHeader(
              navLabel: readOnly
                  ? MessageKey.archiveNav.text
                  : MessageKey.groupListNav.text,
              onNav: () => context.go(readOnly ? '/archive' : '/'),
              badgeLabel: readOnly ? MessageKey.archivedBadge.text : null,
              name: group.name,
              chipLabel: readOnly ? null : MessageKey.groupSettingsChip.text,
              onChip: readOnly
                  ? null
                  : () => context.go('/group/$groupId/settings'),
              total: formatShekel(tripTotal(shown)),
              secondaryLine: groupHeaderLineText(
                memberCount: members.length,
                expenseCount: shown.length,
              ),
              stripe: CategoryStripe(
                segments: [
                  for (final (category, total) in categoryTotals(shown))
                    (color: categoryColor(category), weight: total.value),
                ],
              ),
            ),
      body: expenses == null
          // Local data only: the first stream event arrives at once.
          ? const SizedBox.shrink()
          : _ListWithFade(
              child: ExpenseList(
                expenses: expenses,
                payerNames: payerNames,
                nowUtc: ref.read(clockProvider).nowUtcMillis(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  0,
                  AppSpacing.marginMobile,
                  AppSpacing.listFade + AppSizes.headerOverlap,
                ),
                // Rows are view-only while the Group is archived (FR-6).
                onTap: group == null || readOnly
                    ? null
                    : (e) => context.go('/group/$groupId/edit/${e.id}'),
                onLongPress: group == null || readOnly
                    ? null
                    : (e) =>
                          _delete(context, ref, e, payerNames[e.payerId] ?? ''),
              ),
            ),
      bottomBar: readOnly
          ? _ArchivedBar(
              onRestore: restoring ? null : () => _restore(context, ref),
              onSummary: canSummarize
                  ? () => context.go('/archive/group/$groupId/summary')
                  : null,
            )
          : _AddBar(
              onAdd: canRecord ? () => context.go('/group/$groupId/add') : null,
              onSummary: canSummarize
                  ? () => context.go('/group/$groupId/summary')
                  : null,
            ),
    );
  }
}

/// The list pulled up over the header's bottom edge by 16dp, fading into
/// the canvas over 56dp above the bottom bar. The list's bottom padding lets
/// the last row come to rest above the fade.
class _ListWithFade extends StatelessWidget {
  const _ListWithFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: const Offset(0, -AppSizes.headerOverlap),
            child: child,
          ),
        ),
        BottomFade.positioned(),
      ],
    );
  }
}

/// "+ הוספת הוצאה" as the orange primary on the start side, about two thirds
/// wide, and "סיכום" as the secondary in the remaining third. When [onAdd]
/// is `null` (fewer than two Members) it is disabled and the fixed hint sits
/// directly above the bar. When [onSummary] is `null` "סיכום" is shown at
/// 40% opacity and does nothing.
class _AddBar extends StatelessWidget {
  const _AddBar({required this.onAdd, required this.onSummary});

  final VoidCallback? onAdd;
  final VoidCallback? onSummary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onAdd == null) ...[
          Text(
            MessageKey.needTwoMembers.text,
            textAlign: TextAlign.center,
            style: AppTextStyles.message.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s2),
        ],
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: onAdd,
                child: Text(MessageKey.addExpense.text),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Opacity(
                opacity: onSummary == null ? AppOpacity.disabled : 1,
                child: OutlinedButton(
                  onPressed: onSummary,
                  child: Text(MessageKey.summaryButton.text),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The archive note directly above the bar, with "↩ שחזור מהארכיון" as the
/// orange primary on the start side and "סיכום" as the secondary in the
/// remaining third (an Archived group's Summary stays viewable, FR-6). When
/// [onSummary] is `null` (fewer than two Members) "סיכום" is shown at 40%
/// opacity and does nothing.
class _ArchivedBar extends StatelessWidget {
  const _ArchivedBar({required this.onRestore, required this.onSummary});

  final VoidCallback? onRestore;
  final VoidCallback? onSummary;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ArchiveNote(MessageKey.archiveNote.text),
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: onRestore,
                child: Text(MessageKey.restoreFromArchive.text),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Opacity(
                opacity: onSummary == null ? AppOpacity.disabled : 1,
                child: OutlinedButton(
                  onPressed: onSummary,
                  child: Text(MessageKey.summaryButton.text),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
