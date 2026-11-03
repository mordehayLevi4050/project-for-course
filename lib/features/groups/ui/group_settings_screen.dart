import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/isolate_name.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/result/result.dart';
import '../../../core/text/names.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/compact_top_bar.dart';
import '../../../core/ui/widgets/rename_sheet.dart';
import '../app/group_providers.dart';
import '../domain/group.dart';
import 'member_list.dart';

/// Group settings (FR-2–FR-5), opened from the "⚙ ✎" chip: rename the
/// Group, and add, rename and remove Members. "→" or system back returns to
/// the Group page. The Active toggle and archive arrive in Story 1.2.
class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  /// Whether "+ הוספת משתתף" was tapped: the add field then replaces it and
  /// stays open after each add.
  bool _adding = false;

  Future<void> _renameGroup(Group group) async {
    await showRenameSheet(
      context,
      current: group.name,
      maxLength: maxGroupNameLength,
      onSave: (name) async => switch (await ref
          .read(renameGroupProvider.notifier)
          .submit(id: group.id, name: name)) {
        Ok() => null,
        Failure(:final message) => message,
        null => null,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    final group = ref.watch(groupProvider(groupId)).value;
    final members = ref.watch(membersProvider(groupId)).value ?? [];
    // Keeps the notifier (and its in-flight guard) alive while the sheet is
    // open.
    ref.watch(renameGroupProvider);

    return AppScaffold(
      header: CompactTopBar(
        title: MessageKey.groupSettingsTitle.text,
        onBack: () => context.go('/group/$groupId'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (group != null)
              _SettingsCard(
                child: _SettingsRow(
                  label: MessageKey.groupNameLabel.text,
                  value: MessageKey.rowValue.fill({
                    'value': isolateName(group.name),
                  }),
                  onTap: () => _renameGroup(group),
                ),
              ),
            const SizedBox(height: AppSpacing.s5),
            Text(
              MessageKey.membersCount.fill({'n': '${members.length}'}),
              style: AppTextStyles.sectionTitle.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.s2),
            MemberList(
              members: members,
              footer: _adding
                  ? null
                  : _AddMemberRow(onTap: () => setState(() => _adding = true)),
            ),
            if (_adding) ...[
              const SizedBox(height: AppSpacing.s3),
              MemberAddField(groupId: groupId),
            ],
          ],
        ),
      ),
    );
  }
}

/// A white grouped settings card (`components.settings-row`).
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

/// A 56dp settings row: the [label] on the start side and the [value] on
/// the end side. The whole row is the tap target.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s2,
          ),
          child: Row(
            children: [
              Text(
                label,
                style: AppTextStyles.rowTitle.copyWith(color: AppColors.ink),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.meta.copyWith(
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last row of the Member list: "+ הוספת משתתף" in the secondary ink.
class _AddMemberRow extends StatelessWidget {
  const _AddMemberRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              MessageKey.addMember.text,
              style: AppTextStyles.rowTitle.copyWith(
                color: AppColors.secondaryInk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
