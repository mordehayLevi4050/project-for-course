import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/member_avatar.dart';
import '../../groups/domain/member.dart';

/// Avatars per payer-picker row (`components.payer-picker`).
const int payerPickerColumns = 6;

/// The payer picker (FR-10, DESIGN.md › Payer picker): every Member at once
/// as a tappable avatar in [Member.memberSeq] order, 6 per row, a second
/// start-aligned row for 7–10, never scrolling. The [selectedId] has the
/// ring; the others show at 55% opacity. With no [selectedId] every avatar
/// is neutral.
class PayerPicker extends StatelessWidget {
  const PayerPicker({
    super.key,
    required this.members,
    required this.selectedId,
    required this.onSelect,
  });

  /// In add order (`memberSeq`).
  final List<Member> members;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final names = members.map((m) => m.name);
    final rows = <List<Member>>[
      for (var i = 0; i < members.length; i += payerPickerColumns)
        members.sublist(i, math.min(i + payerPickerColumns, members.length)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Six slots fill the row; shorter rows keep the same gap from the
        // start side.
        final gap = math.max(
          0.0,
          (constraints.maxWidth - payerPickerColumns * AppSizes.avatarSlot) /
              (payerPickerColumns - 1),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (r, row) in rows.indexed) ...[
              if (r > 0) const SizedBox(height: AppSpacing.s2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, member) in row.indexed) ...[
                    if (i > 0) SizedBox(width: gap),
                    GestureDetector(
                      key: ValueKey('payer-${member.id}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(member.id),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppSizes.minTouchTarget,
                        ),
                        child: MemberAvatar(
                          name: member.name,
                          memberSeq: member.memberSeq,
                          label: avatarLabel(member.name, names),
                          selected: selectedId == null
                              ? null
                              : member.id == selectedId,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
