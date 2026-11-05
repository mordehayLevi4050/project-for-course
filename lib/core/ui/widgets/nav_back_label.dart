import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A back nav label: the right-pointing chevron icon (›, start side in RTL)
/// followed by [label] (DESIGN.md › Header block).
///
/// The icon is `Icons.chevron_right` from the bundled MaterialIcons font. It
/// takes the size and color of [style] and scales with the text scale. The
/// label wraps rather than overflowing at a large text scale.
class NavBackLabel extends StatelessWidget {
  const NavBackLabel({super.key, required this.label, required this.style});

  final String label;

  /// Must set `fontSize` and `color`.
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NavChevron(size: style.fontSize, color: style.color),
        const SizedBox(width: AppSpacing.s1),
        Flexible(child: Text(label, style: style)),
      ],
    );
  }
}

/// The back chevron: `Icons.chevron_right`, always pointing right (›).
///
/// `chevron_right` has `matchTextDirection`, so Flutter would mirror it into
/// a left-pointing chevron under RTL; the LTR [Directionality] keeps it
/// pointing right. It scales with the text scale.
class NavChevron extends StatelessWidget {
  const NavChevron({super.key, required this.size, required this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Icon(
        Icons.chevron_right,
        size: size,
        color: color,
        applyTextScaling: true,
      ),
    );
  }
}
