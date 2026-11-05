import 'package:flutter/widgets.dart';

/// The height a `Text(text, style: style, maxLines: maxLines)` placed at
/// [context] takes when laid out at most [maxWidth] wide: the same style
/// merge, text scale, bold-text setting, locale and height behavior as the
/// widget, so a layout can be decided before it is built, in one pass.
double textHeight(
  BuildContext context,
  String text,
  TextStyle style, {
  double maxWidth = double.infinity,
  int? maxLines,
  TextDirection? textDirection,
}) {
  final inherited = DefaultTextStyle.of(context);
  var effective = inherited.style.merge(style);
  if (MediaQuery.boldTextOf(context)) {
    effective = effective.merge(const TextStyle(fontWeight: FontWeight.bold));
  }
  final painter = TextPainter(
    text: TextSpan(text: text, style: effective),
    textDirection: textDirection ?? Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: maxLines ?? inherited.maxLines,
    locale: Localizations.maybeLocaleOf(context),
    textHeightBehavior:
        inherited.textHeightBehavior ??
        DefaultTextHeightBehavior.maybeOf(context),
  )..layout(maxWidth: maxWidth.clamp(1, double.infinity));
  final height = painter.height;
  painter.dispose();
  return height;
}
