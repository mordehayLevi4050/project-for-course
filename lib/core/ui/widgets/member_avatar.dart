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
///
/// In the payer picker [selected] is set: `true` draws a 3dp canvas gap ring
/// plus a 2dp ring in the Member color around the circle, and `false` shows
/// the whole avatar at 55% opacity. `null` (elsewhere) draws neither.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    required this.memberSeq,
    required this.label,
    this.selected,
  });

  final String name;
  final int memberSeq;
  final String label;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final initial = normalizeName(name).characters.take(1).toString();
    final color = AppColors.members[memberColorIndex(memberSeq)];
    const ringOuter = AppSizes.payerGapRing + AppSizes.payerRing;
    Widget circle = Container(
      width: AppSizes.avatar,
      height: AppSizes.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initial,
        maxLines: 1,
        style: AppTextStyles.avatarInitial.copyWith(color: AppColors.onMember),
      ),
    );
    if (selected == true) {
      // The rings are painted outside the circle without changing its
      // layout, so selecting a Payer never moves the picker.
      circle = Stack(
        clipBehavior: Clip.none,
        children: [
          circle,
          const Positioned(
            left: -AppSizes.payerGapRing,
            top: -AppSizes.payerGapRing,
            right: -AppSizes.payerGapRing,
            bottom: -AppSizes.payerGapRing,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(
                    color: AppColors.surfaceBase,
                    width: AppSizes.payerGapRing,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -ringOuter,
            top: -ringOuter,
            right: -ringOuter,
            bottom: -ringOuter,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: AppSizes.payerRing),
              ),
            ),
          ),
        ],
      );
    }
    final avatar = SizedBox(
      width: AppSizes.avatarSlot,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
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
    return selected == false
        ? Opacity(opacity: AppOpacity.unselectedAvatar, child: avatar)
        : avatar;
  }
}
