import 'package:flutter/material.dart';

import '../../../core/ui/theme/tokens.dart';
import '../domain/category.dart';
import 'category_style.dart';

/// Categories per row of the grid and per page of the two-page row.
const int categoriesPerRow = 4;

/// The Category picker (FR-10, DESIGN.md › Category tile): the eight tiles in
/// the fixed order, as a 4×2 grid, or, when [twoPage] (the grid does not fit
/// at the touch-target size), as a two-page sideways row.
///
/// A tap selects a tile and replaces any previous selection; it never saves.
///
/// The two-page row holds the first four tiles on page 1 and the last four
/// on page 2 (on the end side), with no third page. The first tile of the
/// other page peeks in about a quarter tile, two page dots sit centered under
/// the row, and one swipe snaps to the other page. It opens on the page that
/// holds the [selected] Category (page 1 when none), and stays where it is
/// across rebuilds, such as after a validation error.
class CategoryPicker extends StatefulWidget {
  const CategoryPicker({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.twoPage,
  });

  final Category? selected;
  final ValueChanged<Category> onSelect;
  final bool twoPage;

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  PageController? _controller;
  int _page = 0;

  static const double _gap = AppSpacing.s2;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// The controller for a viewport [fraction]; recreated (on the same page)
  /// only when the width changes the fraction.
  PageController _controllerFor(double fraction) {
    final current = _controller;
    if (current != null && current.viewportFraction == fraction) {
      return current;
    }
    if (current == null) {
      final selected = widget.selected;
      _page = selected == null ? 0 : selected.index ~/ categoriesPerRow;
    }
    // The old PageView detaches from it during this frame.
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => current.dispose());
    }
    return _controller = PageController(
      initialPage: _page,
      viewportFraction: fraction,
    );
  }

  /// The height of a two-page row tile [tileWidth] wide: the emoji plus the
  /// tallest label (measured bold, as when selected, at the current text
  /// scale), the padding and the border; at least 64dp. The grid's tiles size
  /// themselves.
  double _tileHeight(BuildContext context, double tileWidth) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    // As the Text widgets do: the style merges the inherited default.
    final inherited = DefaultTextStyle.of(context).style;
    const chrome = 2 * (AppSpacing.s1 + AppSizes.selectedBorder);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: inherited.merge(style)),
        textDirection: direction,
        textScaler: scaler,
      )..layout(maxWidth: (tileWidth - chrome).clamp(1, double.infinity));
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final label = Category.values
        .map((c) => measure(c.label.text, _CategoryTile.labelStyle(true)))
        .reduce((a, b) => a > b ? a : b);
    final emoji = measure(Category.flight.emoji, AppTextStyles.categoryEmoji);
    final content = chrome + emoji + label;
    return content > AppSizes.categoryTileHeight
        ? content.ceilToDouble()
        : AppSizes.categoryTileHeight;
  }

  Widget _tile(Category c) => _CategoryTile(
    category: c,
    selected: c == widget.selected,
    onTap: () => widget.onSelect(c),
  );

  Widget _row(List<Category> categories) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, c) in categories.indexed) ...[
        if (i > 0) const SizedBox(width: _gap),
        Expanded(child: _tile(c)),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    const first = [
      Category.flight,
      Category.hotel,
      Category.car,
      Category.fuel,
    ];
    const second = [
      Category.restaurant,
      Category.foodDrink,
      Category.attractions,
      Category.other,
    ];
    if (!widget.twoPage) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(child: _row(first)),
          const SizedBox(height: _gap),
          IntrinsicHeight(child: _row(second)),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // A page is four tiles plus a trailing gap; a quarter tile of the
        // other page stays visible: page + (page - 4·gap) / 16 = width.
        final pageWidth = (width + _gap / 4) * 16 / 17;
        final controller = _controllerFor(pageWidth / width);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _tileHeight(
                context,
                (pageWidth - 4 * _gap) / categoriesPerRow,
              ),
              child: PageView(
                key: const ValueKey('category-pages'),
                controller: controller,
                padEnds: false,
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  for (final page in [first, second])
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: _gap),
                      child: _row(page),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 2; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.s2),
                  _PageDot(active: i == _page),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

/// A Category tile: the emoji above the name, at least 64dp tall. Selected:
/// a 2dp border and a 16% tint in the Category color, and a bold label.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  /// The tile label; bold when [selected].
  static TextStyle labelStyle(bool selected) => AppTextStyles.label.copyWith(
    color: AppColors.ink,
    fontWeight: selected ? FontWeight.w800 : null,
    fontVariations: selected ? const [FontVariation.weight(800)] : null,
  );

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return GestureDetector(
      key: ValueKey('category-${category.key}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppSizes.categoryTileHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s1,
          vertical: AppSpacing.s1,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(
                  color.withValues(alpha: AppOpacity.selectedTileTint),
                  AppColors.surfaceRaised,
                )
              : AppColors.surfaceRaised,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.lg)),
          border: Border.all(
            color: selected ? color : AppColors.surfaceRaised,
            width: AppSizes.selectedBorder,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: AppTextStyles.categoryEmoji),
            Text(
              category.label.text,
              textAlign: TextAlign.center,
              softWrap: true,
              style: labelStyle(selected),
            ),
          ],
        ),
      ),
    );
  }
}

/// A page dot (`components.page-dot`): filled when [active], otherwise a
/// ring. An indicator only, not a control.
class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.pageDot,
      height: AppSizes.pageDot,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.secondaryInk : null,
        border: active
            ? null
            : Border.all(
                color: AppColors.inkSecondary,
                width: AppSizes.pageDotRing,
              ),
      ),
    );
  }
}
