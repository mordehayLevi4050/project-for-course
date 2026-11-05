import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// One segment of the [CategoryStripe]: a Category color and its share
/// (any positive weight, such as the Category's total in tenths).
typedef StripeSegment = ({Color color, int weight});

/// The category share stripe of the header block (DESIGN.md › Header
/// block): 8dp tall, one segment per Category in proportion to its share of
/// the Trip total, with 2dp gaps. With no segments it is empty (the space is
/// kept, so the header does not jump on the first Expense).
class CategoryStripe extends StatelessWidget {
  const CategoryStripe({super.key, required this.segments});

  final List<StripeSegment> segments;

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.weight > 0).toList();
    return SizedBox(
      height: AppSizes.stripeHeight,
      child: Row(
        // Segments fill the 8dp height (a DecoratedBox has none of its own).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, s) in visible.indexed) ...[
            if (i > 0) const SizedBox(width: AppSizes.stripeGap),
            Expanded(
              flex: s.weight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(AppRadii.full),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
