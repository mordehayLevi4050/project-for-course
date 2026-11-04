import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/result/result.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../app/group_providers.dart';
import 'group_card.dart';

/// The Archive view (FR-6): the group-list layout with the nav line
/// "→ הקבוצות שלי" over the title "ארכיון", gray cards newest first, and no
/// bottom bar. A card opens the Group's read-only page; "↩ שחזור" restores it
/// with no confirmation and opens its page, so this view is never left empty.
class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  Future<void> _restore(BuildContext context, WidgetRef ref, String id) async {
    final result = await ref.read(restoreGroupProvider.notifier).submit(id: id);
    if (!context.mounted) return;
    if (result is Ok) context.go('/group/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(archivedGroupListProvider).value ?? const [];
    // Keeps the notifier (and its in-flight guard) alive.
    final restoring = ref.watch(restoreGroupProvider);
    return AppScaffold(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s5,
          AppSpacing.s1,
          AppSpacing.s5,
          AppSpacing.s6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => context.go('/'),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.minTouchTarget,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 1,
                    child: Text(
                      MessageKey.archiveBackNav.text,
                      style: AppTextStyles.headerSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              MessageKey.archiveTitle.text,
              textAlign: TextAlign.center,
              style: AppTextStyles.screenTitle,
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.s5,
          AppSpacing.marginMobile,
          AppSpacing.s4,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
        itemBuilder: (context, i) {
          final id = items[i].group.id;
          return ArchivedGroupCard(
            item: items[i],
            onTap: () => context.go('/archive/group/$id'),
            onRestore: restoring ? null : () => _restore(context, ref, id),
          );
        },
      ),
    );
  }
}
