import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/money/format_shekel.dart';
import '../../../core/money/tenths.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/group_header.dart';
import '../app/group_providers.dart';

/// The Group page (FR-1). This part shows only the header block: the nav,
/// the name with the "⚙ ✎" chip, the Trip total and the Member count.
/// Expenses, the share stripe and the bottom bar arrive in Stories 1.3–1.4.
class GroupPage extends ConsumerWidget {
  const GroupPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final memberCount = ref.watch(membersProvider(groupId)).value?.length ?? 0;
    return AppScaffold(
      header: group == null
          ? null
          : GroupHeader(
              navLabel: MessageKey.groupListNav.text,
              onNav: () => context.go('/'),
              name: group.name,
              chipLabel: MessageKey.groupSettingsChip.text,
              onChip: () => context.go('/group/$groupId/settings'),
              // The Trip total comes from GroupTotalsPort with Expenses.
              total: formatShekel(Tenths.zero),
              secondaryLine: memberCountText(memberCount),
            ),
      body: const SizedBox.shrink(),
    );
  }
}
