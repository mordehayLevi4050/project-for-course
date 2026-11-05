import 'package:flutter/material.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/money/format_shekel.dart';
import '../../../core/money/tenths.dart';
import '../../../core/text/names.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/member_avatar.dart';
import '../../groups/domain/member.dart';

/// One Transfer on the Summary (DESIGN.md › Transfer card, FR-16): a flat
/// card in `transfer-surface` with a 6dp orange start edge; from the start
/// side the decorative avatar pair (debtor, then receiver, 4dp apart, with
/// nothing between them), the sentence "תשלום נדרש מ{debtor} ל{receiver}"
/// and the amount closing the line on the end side.
///
/// No arrow or other direction symbol, and the card is not tappable. Long
/// names wrap inside the sentence while the amount stays at the end.
class TransferCard extends StatelessWidget {
  const TransferCard({
    super.key,
    required this.debtor,
    required this.receiver,
    required this.amount,
  });

  final Member debtor;
  final Member receiver;
  final Tenths amount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(AppRadii.lg)),
      child: ColoredBox(
        color: AppColors.transferSurface,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                width: AppSizes.startEdge,
                child: ColoredBox(color: AppColors.transferEdge),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.transferCardMinHeight,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.s3),
                  // Read by TalkBack as one line: sentence, then amount.
                  child: MergeSemantics(
                    child: Row(
                      children: [
                        _InitialAvatar(member: debtor),
                        const SizedBox(width: AppSpacing.s1),
                        _InitialAvatar(member: receiver),
                        const SizedBox(width: AppSpacing.s2),
                        Expanded(
                          child: Text(
                            transferLineText(
                              debtor: debtor.name,
                              receiver: receiver.name,
                            ),
                            softWrap: true,
                            style: AppTextStyles.rowTitle.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          formatShekel(amount),
                          style: AppTextStyles.transferAmount.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
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

/// A 32dp circle in the Member color with only the initial; the name is in
/// the sentence, so none is printed under it.
class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: AppSizes.transferAvatar,
        height: AppSizes.transferAvatar,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.members[memberColorIndex(member.memberSeq)],
          shape: BoxShape.circle,
        ),
        child: Text(
          normalizeName(member.name).characters.take(1).toString(),
          maxLines: 1,
          style: AppTextStyles.transferAvatarInitial.copyWith(
            color: AppColors.onMember,
          ),
        ),
      ),
    );
  }
}
