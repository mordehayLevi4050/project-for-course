import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/money/tenths.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../app/group_providers.dart';
import 'group_card.dart';

/// The home screen (FR-1, FR-6, FR-8): the Groups that are not archived, the
/// Active group first with "⭐ פעילה", then newest first. "🗂 ארכיון (n)"
/// sits under the last card and is hidden when no Group is archived.
class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupListProvider).value;
    final totals = ref.watch(groupTotalsProvider).value ?? const {};
    final archivedCount = ref.watch(archivedGroupListProvider).value?.length;
    final archiveLink = archivedCount == null || archivedCount == 0
        ? null
        : ArchiveLink(
            count: archivedCount,
            onTap: () => context.go('/archive'),
          );
    return AppScaffold(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s3,
          AppSpacing.s5,
          AppSpacing.s6,
        ),
        child: Column(
          children: [
            Text(MessageKey.appName.text, style: AppTextStyles.screenTitle),
            Text(
              MessageKey.myGroups.text,
              style: AppTextStyles.headerSecondary,
            ),
          ],
        ),
      ),
      body: switch (groups) {
        // Local data only: the first stream event arrives at once.
        null => const SizedBox.shrink(),
        [] => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.marginMobile),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MessageKey.emptyGroupList.text,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.message.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                if (archiveLink != null) ...[
                  const SizedBox(height: AppSpacing.s3),
                  archiveLink,
                ],
              ],
            ),
          ),
        ),
        final items => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.s5,
            AppSpacing.marginMobile,
            AppSpacing.s4,
          ),
          children: [
            for (final (i, item) in items.indexed) ...[
              if (i > 0) const SizedBox(height: AppSpacing.s2),
              GroupCard(
                item: item,
                total: totals[item.group.id] ?? Tenths.zero,
                onTap: () => context.go('/group/${item.group.id}'),
              ),
            ],
            if (archiveLink != null) ...[
              const SizedBox(height: AppSpacing.s3),
              archiveLink,
            ],
          ],
        ),
      },
      bottomBar: Row(
        children: [
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: () => context.go('/create'),
              child: Text(MessageKey.newGroup.text),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// "🗂 ארכיון (n)": centered, 14sp semibold in the secondary ink, with a
/// 48dp hit area (DESIGN.md › Archive link).
class ArchiveLink extends StatelessWidget {
  const ArchiveLink({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.minTouchTarget,
            minWidth: AppSizes.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            child: Center(
              widthFactor: 1,
              child: Text(
                MessageKey.archiveLink.fill({'n': '$count'}),
                style: AppTextStyles.link.copyWith(
                  color: AppColors.secondaryInk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
