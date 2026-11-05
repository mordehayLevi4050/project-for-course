import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/isolate_name.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/ids/new_id.dart';
import '../../../core/result/result.dart';
import '../../../core/text/names.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/confirm_sheet.dart';
import '../../../core/ui/widgets/member_avatar.dart';
import '../../../core/ui/widgets/name_field.dart';
import '../../../core/ui/widgets/rename_sheet.dart';
import '../app/group_providers.dart';
import '../domain/member.dart';

/// The Member list of Create group (stage 2) and Group settings: one grouped
/// card with a [MemberListRow] per Member, in add order, and an optional [footer]
/// as its last row.
///
/// ✎ opens the Rename sheet. ✕ opens the Remove-member sheet; "הסרה" runs the
/// removal, and a refusal (FR-4) shows inline under that row, replacing any
/// earlier one. When the Group has Expenses the sheet says how they will be
/// shared: "ההוצאות יתחלקו מחדש בין {n} המשתתפים הנותרים.", or "כל ההוצאות
/// יחולו על המשתתף הנותר." when one Member is left; otherwise it has only the
/// title.
class MemberList extends ConsumerStatefulWidget {
  const MemberList({super.key, required this.members, this.footer});

  final List<Member> members;
  final Widget? footer;

  @override
  ConsumerState<MemberList> createState() => _MemberListState();
}

class _MemberListState extends ConsumerState<MemberList> {
  /// The row whose ✕ was refused, and why.
  String? _refusedId;
  MessageKey? _refusal;

  Future<void> _rename(Member member) async {
    await showRenameSheet(
      context,
      current: member.name,
      maxLength: maxMemberNameLength,
      onSave: (name) async => switch (await ref
          .read(renameMemberProvider.notifier)
          .submit(id: member.id, name: name)) {
        Ok() => null,
        Failure(:final message) => message,
        null => null,
      },
    );
  }

  /// The Remove-member body: only when the Group has Expenses (it has a
  /// Trip total in `groupTotalsProvider`), for the Members left.
  String? _removeBody(Member member) {
    final hasExpenses =
        ref.read(groupTotalsProvider).value?.containsKey(member.groupId) ??
        false;
    final left = widget.members.length - 1;
    if (!hasExpenses || left < 1) return null;
    return left == 1
        ? MessageKey.removeMemberBodyOne.text
        : MessageKey.removeMemberBody.fill({'n': '$left'});
  }

  Future<void> _remove(Member member) async {
    final confirmed = await showConfirmSheet(
      context,
      title: MessageKey.removeMemberTitle.fill({
        'name': isolateName(member.name),
      }),
      body: _removeBody(member),
      confirmLabel: MessageKey.removeMemberConfirm.text,
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(removeMemberProvider.notifier)
        .submit(id: member.id);
    if (!mounted || result == null) return;
    setState(() {
      switch (result) {
        case Ok():
          if (_refusedId == member.id) {
            _refusedId = null;
            _refusal = null;
          }
        case Failure(:final message):
          _refusedId = member.id;
          _refusal = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watched so the notifiers (and their in-flight guards) stay alive while
    // a sheet is open.
    ref.watch(renameMemberProvider);
    ref.watch(removeMemberProvider);
    // Watched so the Remove-member body knows whether there are Expenses.
    ref.watch(groupTotalsProvider);

    final members = widget.members;
    final footer = widget.footer;
    final groupNames = members.map((m) => m.name);
    final refusal = _refusal;
    // Each entry is one divided section of the card: a row with its refusal
    // under it, or the footer.
    final rows = <Widget>[
      for (final member in members)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MemberListRow(
              member: member,
              label: avatarLabel(member.name, groupNames),
              onRename: () => _rename(member),
              onRemove: () => _remove(member),
            ),
            if (member.id == _refusedId && refusal != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s3,
                  0,
                  AppSpacing.s3,
                  AppSpacing.s2,
                ),
                child: Text(
                  refusal.text,
                  style: AppTextStyles.message.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
          ],
        ),
      ?footer,
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// A Member row (`components.member-row`): the colored avatar with its
/// [label] under it on the start side, and ✎ and ✕ on the end side, each
/// with a 48dp hit area.
class MemberListRow extends StatelessWidget {
  const MemberListRow({
    super.key,
    required this.member,
    required this.label,
    required this.onRename,
    required this.onRemove,
  });

  final Member member;
  final String label;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.rowMinHeight),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.s3,
          AppSpacing.s2,
          AppSpacing.s1,
          AppSpacing.s2,
        ),
        child: Row(
          children: [
            MemberAvatar(
              name: member.name,
              memberSeq: member.memberSeq,
              label: label,
            ),
            const Spacer(),
            _RowGlyph(glyph: MessageKey.renameGlyph, onTap: onRename),
            _RowGlyph(glyph: MessageKey.removeGlyph, onTap: onRemove),
          ],
        ),
      ),
    );
  }
}

class _RowGlyph extends StatelessWidget {
  const _RowGlyph({required this.glyph, required this.onTap});

  final MessageKey glyph;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: AppSizes.minTouchTarget,
        child: Center(
          child: Text(
            glyph.text,
            style: AppTextStyles.rowTitle.copyWith(
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// The add-member field (FR-2): adds the typed name to [groupId] on "+" or
/// the keyboard action, then clears itself and keeps the focus, so it stays
/// open for the next name. Errors show inline under it.
class MemberAddField extends ConsumerStatefulWidget {
  const MemberAddField({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<MemberAddField> createState() => _MemberAddFieldState();
}

class _MemberAddFieldState extends ConsumerState<MemberAddField> {
  /// Generated when the field opens and again after each successful add.
  String _formId = newId();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  MessageKey? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final result = await ref
        .read(addMemberProvider(widget.groupId).notifier)
        .submit(id: _formId, name: _controller.text);
    if (!mounted || result == null) return;
    setState(() {
      switch (result) {
        case Ok():
          _formId = newId();
          _controller.clear();
          _error = null;
        case Failure(:final message):
          _error = message;
      }
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(addMemberProvider(widget.groupId));
    return NameField(
      controller: _controller,
      focusNode: _focusNode,
      maxLength: maxMemberNameLength,
      autofocus: true,
      hint: MessageKey.memberNamePlaceholder.text,
      error: _error,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      onSubmit: saving ? () {} : _add,
      onAdd: saving ? () {} : _add,
    );
  }
}
