import 'package:flutter/material.dart';

import '../../../core/ui/text_height.dart';
import '../../../core/ui/theme/tokens.dart';
import '../domain/category.dart';
import 'category_style.dart';

/// Categories per row of the grid and per page of the two-page row.
const int categoriesPerRow = 4;

const double _gap = AppSpacing.s2;

const List<Category> _firstRow = [
  Category.flight,
  Category.hotel,
  Category.car,
  Category.fuel,
];
const List<Category> _secondRow = [
  Category.restaurant,
  Category.foodDrink,
  Category.attractions,
  Category.other,
];

/// The height of the 4×2 grid [width] wide at [context], exactly as
/// [CategoryPicker] lays it out (`twoPage: false`, the same [compact]), so
/// the caller can choose between the grid and the two-page row before
/// building either.
double categoryGridHeight(
  BuildContext context,
  double width, {
  required bool compact,
}) {
  final (first, second) = _gridRowHeights(context, width, compact);
  return first + _gap + second;
}

/// The heights of the grid's two rows: in each, the tallest tile's emoji
/// plus label (each label measured both regular and bold, so selecting a
/// tile never changes the size), the padding and the border, rounded up;
/// at least the tile's minimum height.
(double, double) _gridRowHeights(
  BuildContext context,
  double width,
  bool compact,
) {
  final tileWidth = (width - (categoriesPerRow - 1) * _gap) / categoriesPerRow;
  final labelWidth = tileWidth - 2 * (AppSpacing.s1 + AppSizes.selectedBorder);
  final chrome =
      2 * (_CategoryTile.verticalPadding(compact) + AppSizes.selectedBorder);
  final minHeight = _CategoryTile.minHeight(compact);
  double row(List<Category> categories) {
    var tallest = 0.0;
    for (final c in categories) {
      final emoji = textHeight(
        context,
        c.emoji,
        AppTextStyles.categoryEmoji,
        maxWidth: labelWidth,
      );
      var label = 0.0;
      for (final bold in [false, true]) {
        final h = textHeight(
          context,
          c.label.text,
          _CategoryTile.labelStyle(bold),
          maxWidth: labelWidth,
        );
        if (h > label) label = h;
      }
      final content = chrome + emoji + label;
      if (content > tallest) tallest = content;
    }
    return tallest > minHeight ? tallest.ceilToDouble() : minHeight;
  }

  return (row(_firstRow), row(_secondRow));
}

/// The Category picker (FR-10, DESIGN.md › Category tile): the eight tiles in
/// the fixed order, as a 4×2 grid, or, when [twoPage] (the grid does not fit
/// at the touch-target size), as a two-page sideways row.
///
/// A tap selects a tile and replaces any previous selection; it never saves.
/// The grid's [compact] tiles (two payer rows) are shorter; the two-page row
/// always keeps the full tile size.
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
    this.compact = false,
  });

  final Category? selected;
  final ValueChanged<Category> onSelect;
  final bool twoPage;

  /// The grid's compact tiles (DESIGN.md › Add/edit expense composition).
  final bool compact;

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  PageController? _controller;
  int _page = 0;

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

  Widget _tile(Category c, {bool compact = false}) => _CategoryTile(
    category: c,
    selected: c == widget.selected,
    compact: compact,
    onTap: () => widget.onSelect(c),
  );

  Widget _row(List<Category> categories, {bool compact = false}) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, c) in categories.indexed) ...[
        if (i > 0) const SizedBox(width: _gap),
        Expanded(child: _tile(c, compact: compact)),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    const first = _firstRow;
    const second = _secondRow;
    if (!widget.twoPage) {
      // Each row is exactly the height categoryGridHeight() reports.
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = widget.compact;
          final (h1, h2) = _gridRowHeights(
            context,
            constraints.maxWidth,
            compact,
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: h1,
                child: _row(first, compact: compact),
              ),
              const SizedBox(height: _gap),
              SizedBox(
                height: h2,
                child: _row(second, compact: compact),
              ),
            ],
          );
        },
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

/// A Category tile: the emoji above the name, at least 64dp tall (56dp when
/// [compact]). Selected: a 2dp border and a 16% tint in the Category color,
/// and a bold label.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  static double minHeight(bool compact) => compact
      ? AppSizes.categoryTileHeightCompact
      : AppSizes.categoryTileHeight;

  static double verticalPadding(bool compact) => compact
      ? AppSizes.categoryTilePaddingCompact
      : AppSizes.categoryTilePadding;

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
        constraints: BoxConstraints(minHeight: minHeight(compact)),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s1,
          vertical: verticalPadding(compact),
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
