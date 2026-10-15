import 'package:flutter/material.dart';

import '../theme.dart';

/// The GrouPay mark: three overlapping circles (the group) around a shekel sign.
class GroupayLogo extends StatelessWidget {
  final double size;

  const GroupayLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: GroupayLogoPainter()),
    );
  }
}

class GroupayLogoPainter extends CustomPainter {
  /// Fraction of the canvas the mark occupies (used for adaptive icon padding).
  final double scale;

  /// Optional solid fill behind the mark (used for the launcher icon).
  final Color? background;

  GroupayLogoPainter({this.scale = 1, this.background});

  @override
  void paint(Canvas canvas, Size size) {
    if (background != null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = background!);
    }
    final s = size.shortestSide * scale;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    // Three translucent circles in a triangle, overlaps read darker.
    final r = s * 0.29;
    final circles = [
      (Offset(s * 0.5, s * 0.33), GroupayColors.turquoise),
      (Offset(s * 0.31, s * 0.65), GroupayColors.mint),
      (Offset(s * 0.69, s * 0.65), GroupayColors.deepTeal),
    ];
    for (final (center, color) in circles) {
      canvas.drawCircle(center, r, Paint()..color = color.withValues(alpha: 0.82));
    }

    // White badge in the middle with a shekel sign.
    final badgeCenter = Offset(s * 0.5, s * 0.543);
    final badgeRadius = s * 0.17;
    canvas.drawCircle(badgeCenter, badgeRadius, Paint()..color = Colors.white);
    _paintShekel(canvas, badgeCenter, badgeRadius * 1.05);

    canvas.restore();
  }

  /// Draws ₪ as two interlocking hooks, so it does not depend on a font.
  void _paintShekel(Canvas canvas, Offset center, double box) {
    final paint = Paint()
      ..color = GroupayColors.deepTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = box * 0.15
      ..strokeJoin = StrokeJoin.round;
    Offset p(double x, double y) =>
        center + Offset((x - 0.5) * box, (y - 0.5) * box);

    // Left hook: up the left side, across the top, down to the middle.
    canvas.drawPath(
      Path()
        ..moveTo(p(0.12, 0.95).dx, p(0.12, 0.95).dy)
        ..lineTo(p(0.12, 0.08).dx, p(0.12, 0.08).dy)
        ..lineTo(p(0.62, 0.08).dx, p(0.62, 0.08).dy)
        ..lineTo(p(0.62, 0.62).dx, p(0.62, 0.62).dy),
      paint,
    );
    // Right hook: down the right side, across the bottom, up to the middle.
    canvas.drawPath(
      Path()
        ..moveTo(p(0.88, 0.05).dx, p(0.88, 0.05).dy)
        ..lineTo(p(0.88, 0.92).dx, p(0.88, 0.92).dy)
        ..lineTo(p(0.38, 0.92).dx, p(0.38, 0.92).dy)
        ..lineTo(p(0.38, 0.38).dx, p(0.38, 0.38).dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(GroupayLogoPainter old) =>
      old.scale != scale || old.background != background;
}
