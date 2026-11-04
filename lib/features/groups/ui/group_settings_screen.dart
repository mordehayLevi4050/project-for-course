import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/isolate_name.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/result/result.dart';
import '../../../core/text/names.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/active_group_sheet.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/compact_top_bar.dart';
import '../../../core/ui/widgets/confirm_sheet.dart';
import '../../../core/ui/widgets/rename_sheet.dart';
import '../app/group_providers.dart';
import '../domain/group.dart';
import 'member_list.dart';

/// Group settings (FR-2–FR-6, FR-8), opened from the "⚙ ✎" chip: rename the
/// Group, the Active toggle, add, rename and remove Members, and archive.
/// "→" or system back returns to the Group page. It is not reachable for an
/// Archived group (the router redirects to its read-only page).
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

  /// FR-8: on with no other Group active → active at once; on with another
  /// Group active → the Active-group sheet first, and nothing changes unless
  /// it is confirmed; off → unset at once.
  Future<void> _toggleActive(bool on) async {
    final id = widget.groupId;
    if (!on) {
      await ref.read(unsetActiveProvider.notifier).submit(id: id);
      return;
    }
    final current = await ref.read(activeGroupProvider.future);
    if (!mounted) return;
    if (current != null && current.id != id) {
      final confirmed = await showActiveGroupSheet(
        context,
        currentActiveName: current.name,
      );
      if (confirmed != true || !mounted) return;
    }
    await ref.read(setActiveProvider.notifier).submit(id: id);
  }

  Future<void> _archive(Group group) async {
    final confirmed = await showConfirmSheet(
      context,
      title: MessageKey.archiveSheetTitle.fill({
        'group': isolateName(group.name),
      }),
      body: MessageKey.archiveSheetBody.text,
      confirmLabel: MessageKey.archiveSheetConfirm.text,
      destructive: false,
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(archiveGroupProvider.notifier)
        .submit(id: group.id);
    if (!mounted) return;
    // The stack is replaced by the group list.
    if (result is Ok) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    final group = ref.watch(groupProvider(groupId)).value;
    final members = ref.watch(membersProvider(groupId)).value ?? [];
    final isActive = ref.watch(activeGroupIdProvider).value == groupId;
    // Keeps the notifiers (and their in-flight guards) and the Active group
    // alive while a sheet is open.
    ref.watch(renameGroupProvider);
    ref.watch(activeGroupProvider);
    final settingActive =
        ref.watch(setActiveProvider) || ref.watch(unsetActiveProvider);
    final archiving = ref.watch(archiveGroupProvider);

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsRow(
                      label: MessageKey.groupNameLabel.text,
                      value: MessageKey.rowValue.fill({
                        'value': isolateName(group.name),
                      }),
                      onTap: () => _renameGroup(group),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                    _ToggleRow(
                      label: MessageKey.activeToggle.text,
                      value: isActive,
                      onChanged: settingActive ? null : _toggleActive,
                    ),
                  ],
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
            if (group != null) ...[
              const SizedBox(height: AppSpacing.s5),
              _SettingsCard(
                child: _ActionRow(
                  label: MessageKey.archiveAction.text,
                  onTap: archiving ? null : () => _archive(group),
                ),
              ),
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

/// A 56dp settings row with the [label] on the start side and the Toggle
/// (`toggle-off` / `toggle-on`) on the end side. The whole row is the tap
/// target.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged(!value),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.s4,
            AppSpacing.s1,
            AppSpacing.s2,
            AppSpacing.s1,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.rowTitle.copyWith(color: AppColors.ink),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.toggleOn,
                inactiveTrackColor: AppColors.toggleOff,
                activeThumbColor: AppColors.surfaceRaised,
                inactiveThumbColor: AppColors.surfaceRaised,
                trackOutlineColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.toggleOn
                      : AppColors.toggleOff,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single-row action card, such as "🗂 העברה לארכיון", in the secondary
/// ink.
class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

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
              label,
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
