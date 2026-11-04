import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/ids/new_id.dart';
import '../../../core/result/result.dart';
import '../../../core/text/names.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/active_group_sheet.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/compact_top_bar.dart';
import '../../../core/ui/widgets/name_field.dart';
import '../app/group_providers.dart';
import '../domain/group.dart';
import 'member_list.dart';

/// Create group (FR-1, FR-2): two stages on one screen.
///
/// Stage 1 names the Group and saves it. Stage 2 adds Members, each saved as
/// soon as it is added; "סיום" or system back opens the new Group's page.
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  /// Generated when the form opens (AD-23).
  final String _groupFormId = newId();
  final _nameController = TextEditingController();
  MessageKey? _nameError;

  /// Set once stage 1 is saved: the screen is then in stage 2.
  Group? _group;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final result = await ref
        .read(createGroupProvider.notifier)
        .submit(id: _groupFormId, name: _nameController.text);
    if (!mounted || result == null) return;
    switch (result) {
      case Failure(:final message):
        setState(() => _nameError = message);
      case Ok(:final value):
        await _offerActive(value);
        if (!mounted) return;
        setState(() {
          _group = value;
          _nameError = null;
        });
    }
  }

  /// FR-7: right after the Group is saved, before any Member is added, the
  /// Active-group sheet offers to make it active, warning when another Group
  /// is active. Any answer (or a dismissal) then opens stage 2.
  Future<void> _offerActive(Group group) async {
    final current = await ref.read(activeGroupProvider.future);
    if (!mounted) return;
    final confirmed = await showActiveGroupSheet(
      context,
      currentActiveName: current?.name,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(setActiveProvider.notifier).submit(id: group.id);
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    return group == null ? _buildNaming() : _MembersStage(group: group);
  }

  Widget _buildNaming() {
    final saving = ref.watch(createGroupProvider);
    // Kept alive for the Active-group sheet right after the save (FR-7).
    ref.watch(activeGroupProvider);
    ref.watch(setActiveProvider);
    return AppScaffold(
      header: CompactTopBar(
        title: MessageKey.newGroupTitle.text,
        // ✕ on stage 1 leaves without creating anything.
        onClose: () => context.go('/'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginMobile),
        children: [
          Text(
            MessageKey.groupNameLabel.text,
            style: AppTextStyles.label.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpacing.s2),
          NameField(
            controller: _nameController,
            maxLength: maxGroupNameLength,
            autofocus: true,
            error: _nameError,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            onSubmit: _createGroup,
          ),
        ],
      ),
      bottomBar: _PrimaryBar(
        label: MessageKey.createGroup.text,
        onPressed: saving ? null : _createGroup,
      ),
    );
  }
}

/// Stage 2: the Members section of the Group just created. Each added name
/// appears at once as a row with ✎ and ✕ (shared with Group settings).
class _MembersStage extends ConsumerWidget {
  const _MembersStage({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider(group.id)).value ?? [];
    void finish() => context.go('/group/${group.id}');
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) finish();
      },
      child: AppScaffold(
        header: CompactTopBar(title: group.name),
        // At most 10 rows: built eagerly, so the add field always exists
        // and can scroll itself into view while typing.
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                MessageKey.membersSection.text,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.s2),
              if (members.isNotEmpty) ...[
                MemberList(members: members),
                const SizedBox(height: AppSpacing.s3),
              ],
              MemberAddField(groupId: group.id),
            ],
          ),
        ),
        bottomBar: _PrimaryBar(label: MessageKey.done.text, onPressed: finish),
      ),
    );
  }
}

/// The bottom bar with the single orange primary button on the start side,
/// about two thirds wide.
class _PrimaryBar extends StatelessWidget {
  const _PrimaryBar({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: FilledButton(onPressed: onPressed, child: Text(label)),
        ),
        const Spacer(),
      ],
    );
  }
}
