import 'package:flutter/material.dart';

import '../../../core/i18n/expense_time.dart';
import '../../../core/i18n/isolate_name.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/money/format_shekel.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/motion.dart';
import '../domain/expense.dart';
import 'category_style.dart';

/// The Expense list of the Group page (FR-12): newest first by `saveSeq`
/// (the order [expenses] comes in), or "עדיין אין הוצאות" when empty.
///
/// A row that appears after the list was first shown (a new Expense) slides
/// into place through [AppAnimation.expenseRowSlideIn]; rows present on the
/// first show do not move.
///
/// A tap on a row calls [onTap] (Edit expense) and a long-press calls
/// [onLongPress] (the Delete sheet). Both are `null` in an Archived group,
/// where rows are view-only. There is no swipe gesture.
class ExpenseList extends StatefulWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.payerNames,
    required this.nowUtc,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.onLongPress,
  });

  final List<Expense> expenses;

  /// Member names by id, for the meta line.
  final Map<String, String> payerNames;

  /// Now, as UTC epoch millis, for the Expense time format.
  final int nowUtc;
  final EdgeInsets padding;
  final ValueChanged<Expense>? onTap;
  final ValueChanged<Expense>? onLongPress;

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  /// Ids that arrived after the first show; their rows slide in once.
  final Set<String> _fresh = {};

  @override
  void didUpdateWidget(ExpenseList old) {
    super.didUpdateWidget(old);
    final before = {for (final e in old.expenses) e.id};
    for (final e in widget.expenses) {
      if (!before.contains(e.id)) _fresh.add(e.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenses = widget.expenses;
    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.marginMobile),
          child: Text(
            MessageKey.noExpenses.text,
            textAlign: TextAlign.center,
            style: AppTextStyles.message.copyWith(color: AppColors.inkMuted),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: widget.padding,
      itemCount: expenses.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s2),
      itemBuilder: (context, i) {
        final expense = expenses[i];
        final onTap = widget.onTap;
        final onLongPress = widget.onLongPress;
        final row = ExpenseRowCard(
          expense: expense,
          payerName: widget.payerNames[expense.payerId] ?? '',
          nowUtc: widget.nowUtc,
          onTap: onTap == null ? null : () => onTap(expense),
          onLongPress: onLongPress == null ? null : () => onLongPress(expense),
        );
        return _fresh.contains(expense.id)
            ? _SlideIn(
                key: ValueKey(expense.id),
                onDone: () => _fresh.remove(expense.id),
                child: row,
              )
            : KeyedSubtree(key: ValueKey(expense.id), child: row);
      },
    );
  }
}

/// An Expense row (DESIGN.md › Expense row): a white card of at least 72dp
/// with a 6dp start-edge stripe and a 46dp emoji circle tinted 15% in the
/// Category color, the title (the Category name, or the Description for
/// *Other*), the meta line "payer · time" and the amount on the end side.
/// [onTap] and [onLongPress] are `null` when the row is view-only.
class ExpenseRowCard extends StatelessWidget {
  const ExpenseRowCard({
    super.key,
    required this.expense,
    required this.payerName,
    required this.nowUtc,
    this.onTap,
    this.onLongPress,
  });

  final Expense expense;
  final String payerName;
  final int nowUtc;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(expense.category);
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.lg)),
        child: Material(
          color: AppColors.surfaceRaised,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: AppSizes.startEdge,
                    child: ColoredBox(color: color),
                  ),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: AppSizes.cardMinHeight,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.s3),
                      child: Row(
                        children: [
                          Container(
                            width: AppSizes.expenseIconCircle,
                            height: AppSizes.expenseIconCircle,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: color.withValues(
                                alpha: AppOpacity.categoryTint,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              expense.category.emoji,
                              style: AppTextStyles.categoryEmoji,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s3),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title,
                                  style: AppTextStyles.rowTitle.copyWith(
                                    color: AppColors.ink,
                                  ),
                                ),
                                Text(
                                  MessageKey.expenseMeta.fill({
                                    'payer': isolateName(payerName),
                                    'time': formatExpenseTime(
                                      expense.createdAt,
                                      nowUtc,
                                    ),
                                  }),
                                  style: AppTextStyles.meta.copyWith(
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s2),
                          Text(
                            formatShekel(expense.amount),
                            style: AppTextStyles.rowAmount.copyWith(
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The expense line of the Delete sheet (FR-14): "{emoji} {title} · {payer}
/// · {amount}", e.g. "🛒 אוכל ושתייה · מוטי · ₪87.4". A Description (the
/// title under *Other*) and the Payer name are bidi-isolated.
String expenseLineText(Expense expense, String payerName) =>
    MessageKey.expenseLine.fill({
      'emoji': expense.category.emoji,
      'title': expense.description == null
          ? expense.title
          : isolateName(expense.title),
      'payer': isolateName(payerName),
      'amount': formatShekel(expense.amount),
    });

/// Slides a new row into the top of the list once; instant when "Remove
/// animations" is on.
class _SlideIn extends StatefulWidget {
  const _SlideIn({super.key, required this.child, required this.onDone});

  final Widget child;
  final VoidCallback onDone;

  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final duration = appAnimationDuration(
      context,
      AppAnimation.expenseRowSlideIn,
    );
    if (duration == Duration.zero) {
      _controller.value = 1;
      widget.onDone();
    } else {
      _controller.duration = duration;
      _controller.forward().whenComplete(widget.onDone);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.bottomCenter,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
