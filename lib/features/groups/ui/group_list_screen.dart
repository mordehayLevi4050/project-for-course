import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../app/group_providers.dart';
import '../domain/group.dart';

/// The home screen: the list of Groups, newest first (FR-1).
class GroupListScreen extends ConsumerWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupListProvider).value;
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
            child: Text(
              MessageKey.emptyGroupList.text,
              textAlign: TextAlign.center,
              style: AppTextStyles.message.copyWith(color: AppColors.inkMuted),
            ),
          ),
        ),
        final items => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            AppSpacing.s5,
            AppSpacing.marginMobile,
            AppSpacing.s4,
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
          itemBuilder: (context, i) => _GroupCard(
            item: items[i],
            onTap: () => context.go('/group/${items[i].group.id}'),
          ),
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

/// A Group card: the name and the Member count. The Trip total joins it
/// with Expenses (Story 1.3), the Active badge with Story 1.2.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.item, required this.onTap});

  final GroupListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.cardMinHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.group.name,
              style: AppTextStyles.rowTitle.copyWith(color: AppColors.ink),
            ),
            Text(
              memberCountText(item.memberCount),
              style: AppTextStyles.meta.copyWith(color: AppColors.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
