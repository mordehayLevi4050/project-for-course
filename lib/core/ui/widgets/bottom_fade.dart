import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The 56dp fade into the canvas at the bottom edge of a scrolling list
/// (`surface-base` from transparent to opaque). It ignores touches. Place it
/// in a `Stack` over the list, at the bottom; [BottomFade.positioned] does
/// that.
class BottomFade extends StatelessWidget {
  const BottomFade({super.key});

  /// The fade pinned to the bottom of the enclosing `Stack`.
  static Widget positioned() => const Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    height: AppSpacing.listFade,
    child: BottomFade(),
  );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surfaceBase.withValues(alpha: 0),
              AppColors.surfaceBase,
            ],
          ),
        ),
      ),
    );
  }
}
