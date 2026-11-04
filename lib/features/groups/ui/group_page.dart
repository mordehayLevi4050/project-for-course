import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/money/format_shekel.dart';
import '../../../core/money/tenths.dart';
import '../../../core/policy/group_rules.dart';
import '../../../core/result/result.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/group_header.dart';
import '../app/group_providers.dart';

/// The Group page (FR-1, FR-6). This part shows the header block: the nav,
/// the name with the "⚙ ✎" chip, the Trip total and the Member count.
/// Expenses, the share stripe and the Add/Summary bar arrive in Stories
/// 1.3–1.4.
///
/// Read-only mode comes from `isGroupMutable`, never from the route. An
/// Archived group shows the nav "→ ארכיון", the badge "🗂 בארכיון", no chip,
/// and the archive note above a bottom bar whose primary is
/// "↩ שחזור מהארכיון".
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final memberCount = ref.watch(membersProvider(groupId)).value?.length ?? 0;
    final readOnly =
        group != null &&
        !isGroupMutable((isArchived: group.isArchived)).isAllowed;
    // Keeps the notifier (and its in-flight guard) alive.
    final restoring = ref.watch(restoreGroupProvider);
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
              // The Trip total comes from GroupTotalsPort with Expenses.
              total: formatShekel(Tenths.zero),
              secondaryLine: memberCountText(memberCount),
            ),
      body: const SizedBox.shrink(),
      bottomBar: readOnly
          ? _ArchivedBar(
              onRestore: restoring ? null : () => _restore(context, ref),
            )
          : null,
    );
  }
}

/// The archive note directly above the bar, with "↩ שחזור מהארכיון" as the
/// orange primary on the start side.
class _ArchivedBar extends StatelessWidget {
  const _ArchivedBar({required this.onRestore});

  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.archivedSurface,
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s2,
            ),
            child: Text(
              MessageKey.archiveNote.text,
              style: AppTextStyles.message.copyWith(
                color: AppColors.archivedInk,
              ),
            ),
          ),
        ),
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
            const Spacer(),
          ],
        ),
      ],
    );
  }
}
