import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The archive note strip (DESIGN.md › Archive note, FR-6): [text] in
/// `archived-ink` and `typography.message` on `archived-surface`. The
/// archived Group page puts it above its bottom bar, the archived Summary
/// under the Transfer cards.
class ArchiveNote extends StatelessWidget {
  const ArchiveNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.archivedSurface,
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        child: Text(
          text,
          style: AppTextStyles.message.copyWith(color: AppColors.archivedInk),
        ),
      ),
    );
  }
}
