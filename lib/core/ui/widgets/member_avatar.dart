import 'package:flutter/material.dart';

import '../../text/names.dart';
import '../theme/tokens.dart';

/// The index into `AppColors.members` for a Member: by add order
/// (`memberSeq`, starting at 1), wrapping after 6 (DESIGN.md › Colors).
int memberColorIndex(int memberSeq) =>
    (memberSeq - 1) % AppColors.members.length;

/// The text under a Member's circle: the first word of [name], or the full
/// name when another Member of the Group has the same first word.
///
/// [groupNames] are the names of the Group's Members; it may include [name]
/// itself. Words are compared by `nameKey`, so case is ignored.
String avatarLabel(String name, Iterable<String> groupNames) {
  final ownKey = nameKey(name);
  final first = _firstWord(name);
  final firstKey = nameKey(first);
  final clash = groupNames.any(
    (other) =>
        nameKey(other) != ownKey && nameKey(_firstWord(other)) == firstKey,
  );
  return clash ? normalizeName(name) : first;
}

String _firstWord(String name) {
  final normalized = normalizeName(name);
  final space = normalized.indexOf(RegExp(r'\s'));
  return space < 0 ? normalized : normalized.substring(0, space);
}

/// A Member avatar: an [AppSizes.avatar] circle in the Member color with the
/// first letter of the name, in an [AppSizes.avatarSlot]-wide slot, with the
/// [label] (see [avatarLabel]) under it. The label wraps to two lines and is
/// never truncated.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    required this.memberSeq,
    required this.label,
  });

  final String name;
  final int memberSeq;
  final String label;

  @override
  Widget build(BuildContext context) {
    final initial = normalizeName(name).characters.take(1).toString();
    return SizedBox(
      width: AppSizes.avatarSlot,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.avatar,
            height: AppSizes.avatar,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.members[memberColorIndex(memberSeq)],
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              maxLines: 1,
              style: AppTextStyles.avatarInitial.copyWith(
                color: AppColors.onMember,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: AppTextStyles.label.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}
