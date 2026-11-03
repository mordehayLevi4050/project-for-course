import 'package:flutter/widgets.dart';

/// The only animations the app has (EXPERIENCE.md › Motion, AD-22).
/// Everything else is instant.
enum AppAnimation {
  /// A newly saved Expense row slides into the top of the list.
  expenseRowSlideIn(Duration(milliseconds: 250)),

  /// Bottom sheets slide up and down.
  sheetSlide(Duration(milliseconds: 250));

  const AppAnimation(this.duration);

  /// The duration when animations are on.
  final Duration duration;
}

/// The duration to use for [animation] here: [Duration.zero] when the system
/// "Remove animations" setting is on, so the animation is skipped.
Duration appAnimationDuration(BuildContext context, AppAnimation animation) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false
    ? Duration.zero
    : animation.duration;
