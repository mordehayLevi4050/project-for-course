import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/ids/new_id.dart';
import '../../../core/result/result.dart';
import '../../../core/text/names.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/compact_top_bar.dart';
import '../../../core/ui/widgets/member_avatar.dart';
import '../../../core/ui/widgets/name_field.dart';
import '../app/group_providers.dart';
import '../domain/group.dart';
import '../domain/member.dart';

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
    setState(() {
      switch (result) {
        case Ok(:final value):
          _group = value;
          _nameError = null;
        case Failure(:final message):
          _nameError = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    return group == null ? _buildNaming() : _MembersStage(group: group);
  }

  Widget _buildNaming() {
    final saving = ref.watch(createGroupProvider);
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

/// Stage 2: the Members section of the Group just created.
class _MembersStage extends ConsumerStatefulWidget {
  const _MembersStage({required this.group});

  final Group group;

  @override
  ConsumerState<_MembersStage> createState() => _MembersStageState();
}

class _MembersStageState extends ConsumerState<_MembersStage> {
  /// Generated when the field opens and again after each successful add.
  String _memberFormId = newId();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  MessageKey? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final result = await ref
        .read(addMemberProvider(widget.group.id).notifier)
        .submit(id: _memberFormId, name: _controller.text);
    if (!mounted || result == null) return;
    setState(() {
      switch (result) {
        case Ok():
          _memberFormId = newId();
          _controller.clear();
          _error = null;
        case Failure(:final message):
          _error = message;
      }
    });
    _focusNode.requestFocus();
  }

  void _finish() => context.go('/group/${widget.group.id}');

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider(widget.group.id)).value ?? [];
    final saving = ref.watch(addMemberProvider(widget.group.id));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: AppScaffold(
        header: CompactTopBar(title: widget.group.name),
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
              for (final member in members) ...[
                _MemberRow(
                  member: member,
                  groupNames: members.map((m) => m.name),
                ),
                const SizedBox(height: AppSpacing.s2),
              ],
              NameField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: maxMemberNameLength,
                autofocus: true,
                hint: MessageKey.memberNamePlaceholder.text,
                error: _error,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmit: saving ? () {} : _addMember,
                onAdd: saving ? () {} : _addMember,
              ),
            ],
          ),
        ),
        bottomBar: _PrimaryBar(label: MessageKey.done.text, onPressed: _finish),
      ),
    );
  }
}

/// A Member row: the colored avatar with the first word under it. Rename
/// (✎) and remove (✕) join the row with Group settings (part 2b).
class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.groupNames});

  final Member member;
  final Iterable<String> groupNames;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
      ),
      alignment: AlignmentDirectional.centerStart,
      child: MemberAvatar(
        name: member.name,
        memberSeq: member.memberSeq,
        label: avatarLabel(member.name, groupNames),
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
