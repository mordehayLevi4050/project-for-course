import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/ids/new_id.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/tenths.dart';
import '../../../core/result/result.dart';
import '../../../core/text/description.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/compact_top_bar.dart';
import '../../../core/ui/widgets/exit_sheet.dart';
import '../../groups/app/group_providers.dart';
import '../app/expense_providers.dart';
import '../domain/category.dart';
import 'category_picker.dart';
import 'keypad.dart';
import 'payer_picker.dart';

/// Add expense (FR-10, FR-11), at `group/:id/add`.
///
/// Top to bottom: the compact top bar (✕, the group name), the Amount with
/// the ₪ mark and a caret, the message slot, the payer picker, the Category
/// grid (or the two-page row when the grid does not fit), then the keypad
/// and the wide "שמירה" pinned at the bottom. Nothing above the keypad
/// scrolls in normal use. *Other* swaps the keypad for the Description field
/// and the system keyboard.
///
/// The Expense id is generated when the screen opens (AD-23). Save validates
/// (Amount, then Category, then the *Other* Description) with the message in
/// the slot and all input kept; on success it stores the Expense once and
/// returns to the Group page. ✕ or system back with unsaved input opens the
/// Exit sheet.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  /// Generated once, when the form opens (AD-23).
  final String _formId = newId();

  final _description = TextEditingController();

  /// The keypad buffer (`core/money`).
  String _buffer = '';
  Category? _category;

  /// The selected Payer and the default it started from; set once, when the
  /// default is known.
  String? _payerId;
  String? _defaultPayerId;
  bool _payerReady = false;

  /// The FR-11 message in the slot under the Amount.
  MessageKey? _error;
  bool _saving = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  /// Unsaved input (EXPERIENCE.md › Exit sheet): a typed Amount or
  /// Description, a selected Category, or a Payer other than the default.
  bool get _hasUnsavedInput =>
      _buffer.isNotEmpty ||
      _description.text.isNotEmpty ||
      _category != null ||
      _payerId != _defaultPayerId;

  void _leave() => context.go('/group/${widget.groupId}');

  Future<void> _close() async {
    if (!_hasUnsavedInput) return _leave();
    final confirmed = await showExitSheet(context);
    if (confirmed == true && mounted) _leave();
  }

  void _press(KeypadKey key) => setState(() {
    _buffer = pressKeypadKey(_buffer, key);
    if (_error == MessageKey.invalidAmount) _error = null;
  });

  void _selectCategory(Category category) => setState(() {
    _category = category;
    if (_error == MessageKey.chooseCategory ||
        _error == MessageKey.descriptionRequired) {
      _error = null;
    }
  });

  Future<void> _save() async {
    if (_saving) return;
    final payerId = _payerId;
    if (payerId == null) return;

    Tenths? amount;
    MessageKey? error;
    switch (parseAmount(_buffer)) {
      case Ok(:final value):
        amount = value;
      case Failure(:final message):
        error = message;
    }
    final category = _category;
    if (error == null && category == null) error = MessageKey.chooseCategory;
    if (error == null &&
        category!.needsDescription &&
        isBlankDescription(_description.text)) {
      error = MessageKey.descriptionRequired;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _saving = true);
    final result = await ref
        .read(addExpenseProvider.notifier)
        .submit(
          id: _formId,
          groupId: widget.groupId,
          payerId: payerId,
          amount: amount!,
          category: category!,
          description: category.needsDescription ? _description.text : null,
        );
    if (!mounted) return;
    switch (result) {
      case Ok():
        _leave();
      case Failure(:final message):
        setState(() {
          _error = message;
          _saving = false;
        });
      case null:
        setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId;
    final group = ref.watch(groupProvider(groupId)).value;
    final members = ref.watch(membersProvider(groupId)).value ?? const [];
    final defaultPayer = ref.watch(defaultPayerIdProvider(groupId));
    // Keeps the notifier (and its in-flight guard) alive.
    ref.watch(addExpenseProvider);
    if (!_payerReady && defaultPayer.hasValue) {
      _payerReady = true;
      _payerId = _defaultPayerId = defaultPayer.value;
    }
    final other = _category?.needsDescription ?? false;
    final scaler = MediaQuery.textScalerOf(context);
    final metrics = _TopMetrics(scaler, payerRows: _rowsFor(members.length));

    return PopScope(
      canPop: !_hasUnsavedInput,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AppScaffold(
        header: CompactTopBar(title: group?.name ?? '', onClose: _close),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final twoPage = metrics.gridHeight > constraints.maxHeight;
                  // A safety net only: in normal use the region fits and
                  // never scrolls (the Categories switch to the two-page
                  // row first).
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile,
                      vertical: AppSpacing.s3,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AmountDisplay(buffer: _buffer),
                        Text(
                          _error?.text ?? '',
                          key: const ValueKey('amount-message'),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.message.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s3),
                        PayerPicker(
                          members: members,
                          selectedId: _payerId,
                          onSelect: (id) => setState(() => _payerId = id),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        CategoryPicker(
                          selected: _category,
                          onSelect: _selectCategory,
                          twoPage: twoPage,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _BottomPanel(
              input: other
                  ? TextField(
                      key: const ValueKey('description-field'),
                      controller: _description,
                      autofocus: true,
                      style: AppTextStyles.rowTitle.copyWith(
                        color: AppColors.ink,
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {
                        if (_error == MessageKey.descriptionRequired) {
                          _error = null;
                        }
                      }),
                      onEditingComplete: _save,
                      decoration: InputDecoration(
                        hintText: MessageKey.descriptionHint.text,
                        constraints: const BoxConstraints(
                          minHeight: AppSizes.textFieldHeight,
                        ),
                      ),
                    )
                  : Keypad(onKey: _press),
              save: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(MessageKey.save.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _rowsFor(int memberCount) =>
      math.max(1, (memberCount / payerPickerColumns).ceil());
}

/// The Amount: the ₪ mark tinted `currency-mark`, the typed buffer and a
/// static caret, as an LTR run (46sp).
class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.buffer});

  final String buffer;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.textScalerOf(context)
        .scale(AppTextStyles.amountEntry.fontSize!);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            MessageKey.currencyMark.text,
            style: AppTextStyles.amountEntry.copyWith(
              color: AppColors.currencyMark,
            ),
          ),
          Flexible(
            child: Text(
              buffer,
              key: const ValueKey('amount-text'),
              maxLines: 1,
              style: AppTextStyles.amountEntry.copyWith(color: AppColors.ink),
            ),
          ),
          Container(
            width: AppSizes.caretWidth,
            height: height,
            color: AppColors.inputBorderFocus,
          ),
        ],
      ),
    );
  }
}

/// The white panel pinned at the bottom (`rounded.xl` top corners): the
/// keypad or the Description field, then the wide Save.
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.input, required this.save});

  final Widget input;
  final Widget save;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.s3,
          AppSpacing.marginMobile,
          AppSpacing.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            input,
            const SizedBox(height: AppSpacing.s3),
            save,
          ],
        ),
      ),
    );
  }
}

/// Estimated heights of the region above the keypad, for choosing between
/// the 4×2 grid and the two-page row (FR-10). Every line is taken at its
/// scaled size with generous line spacing, and avatar names and tile labels
/// at two lines, so the grid is chosen only when it surely fits.
final class _TopMetrics {
  _TopMetrics(this._scaler, {required this.payerRows});

  final TextScaler _scaler;
  final int payerRows;

  static const double _lineFactor = 1.4;

  double _line(TextStyle style) => _scaler.scale(style.fontSize!) * _lineFactor;

  /// A Category tile: emoji, a two-line label, padding and border; at least
  /// 64dp.
  double get tileHeight => math.max(
    AppSizes.categoryTileHeight,
    2 * (AppSpacing.s1 + AppSizes.selectedBorder) +
        _line(AppTextStyles.categoryEmoji) +
        2 * _line(AppTextStyles.label),
  );

  double get _payerHeight =>
      payerRows *
          (AppSizes.avatar + AppSpacing.s1 + 2 * _line(AppTextStyles.label)) +
      (payerRows - 1) * AppSpacing.s2;

  /// Everything above the Categories, with the region's padding.
  double get _aboveCategories =>
      2 * AppSpacing.s3 +
      _line(AppTextStyles.amountEntry) +
      _line(AppTextStyles.message) +
      AppSpacing.s3 +
      _payerHeight +
      AppSpacing.s4;

  /// The region's height with the 4×2 grid.
  double get gridHeight => _aboveCategories + 2 * tileHeight + AppSpacing.s2;
}
