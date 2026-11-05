import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/expense_time.dart';
import '../../../core/i18n/message_key.dart';
import '../../../core/ids/new_id.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/tenths.dart';
import '../../../core/result/result.dart';
import '../../../core/text/description.dart';
import '../../../core/time/clock_provider.dart';
import '../../../core/ui/theme/tokens.dart';
import '../../../core/ui/widgets/app_scaffold.dart';
import '../../../core/ui/widgets/compact_top_bar.dart';
import '../../../core/ui/widgets/delete_sheet.dart';
import '../../../core/ui/widgets/exit_sheet.dart';
import '../../../core/ui/widgets/snackbar.dart';
import '../../groups/app/group_providers.dart';
import '../app/expense_providers.dart';
import '../domain/category.dart';
import '../domain/expense.dart';
import 'category_picker.dart';
import 'expense_list.dart';
import 'keypad.dart';
import 'payer_picker.dart';

/// Add expense (FR-10, FR-11), at `group/:id/add`, and Edit expense (FR-13,
/// FR-14), at `group/:id/edit/:eid` when [expenseId] is given.
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
///
/// Edit expense opens with every field filled from the saved Expense (once,
/// when it is first read; the Categories open on the page that holds its
/// Category), shows the meta line "נרשם {time}" (plus " · נערך {time}" once
/// it was saved with a change) under the Amount, and carries the
/// "🗑 מחיקה" chip, which opens the Delete sheet. Unsaved input is any field
/// that differs from the saved Expense; saving with none closes the screen
/// and writes nothing.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.groupId, this.expenseId});

  final String groupId;

  /// The Expense being edited; `null` on Add expense.
  final String? expenseId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  /// Generated once, when the form opens (AD-23); the edited Expense's id on
  /// Edit expense.
  late final String _formId = widget.expenseId ?? newId();

  bool get _isEdit => widget.expenseId != null;

  /// Edit expense: the saved Expense the form was filled from.
  Expense? _saved;

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
  bool _leaving = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  /// Unsaved input (EXPERIENCE.md › Exit sheet). On Add expense: a typed
  /// Amount or Description, a selected Category, or a Payer other than the
  /// default. On Edit expense: any field that differs from the saved
  /// Expense (the Description counts only under *Other*, the only Category
  /// that stores one).
  bool get _hasUnsavedInput {
    if (!_isEdit) {
      return _buffer.isNotEmpty ||
          _description.text.isNotEmpty ||
          _category != null ||
          _payerId != _defaultPayerId;
    }
    final saved = _saved;
    if (saved == null) return false;
    final amountSame = switch (parseAmount(_buffer)) {
      Ok(:final value) => value == saved.amount,
      Failure() => false,
    };
    return !amountSame ||
        _category != saved.category ||
        _payerId != saved.payerId ||
        (_category!.needsDescription &&
            normalizeDescription(_description.text) != saved.description);
  }

  /// Fills the form from the saved Expense, once.
  void _prefill(Expense saved) {
    _saved = saved;
    _buffer = amountToKeypadBuffer(saved.amount);
    _category = saved.category;
    _payerId = _defaultPayerId = saved.payerId;
    _description.text = saved.description ?? '';
    _payerReady = true;
  }

  void _leave() {
    _leaving = true;
    context.go('/group/${widget.groupId}');
  }

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
    // Edit with no field changed: close, write nothing.
    if (_isEdit && !_hasUnsavedInput) return _leave();

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
    final description = category!.needsDescription ? _description.text : null;
    final result = _isEdit
        ? await ref
              .read(editExpenseProvider.notifier)
              .submit(
                id: _formId,
                payerId: payerId,
                amount: amount!,
                category: category,
                description: description,
              )
        : await ref
              .read(addExpenseProvider.notifier)
              .submit(
                id: _formId,
                groupId: widget.groupId,
                payerId: payerId,
                amount: amount!,
                category: category,
                description: description,
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

  /// The "🗑 מחיקה" chip: the Delete sheet, then the delete, the snackbar
  /// "ההוצאה נמחקה" and the Group page.
  Future<void> _delete(String payerName) async {
    final saved = _saved;
    if (saved == null || _saving) return;
    final confirmed = await showDeleteSheet(
      context,
      line: expenseLineText(saved, payerName),
    );
    if (confirmed != true || !mounted || _saving) return;
    // Save is disabled while the delete is in flight.
    setState(() => _saving = true);
    final result = await ref
        .read(deleteExpenseProvider.notifier)
        .submit(id: saved.id);
    if (!mounted) return;
    switch (result) {
      case Ok():
        showAppSnackbar(MessageKey.expenseDeleted);
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
    if (_isEdit) {
      final saved = ref.watch(expenseProvider(_formId));
      // Keep the notifiers (and their in-flight guards) alive.
      ref.watch(editExpenseProvider);
      ref.watch(deleteExpenseProvider);
      if (!_payerReady && saved.hasValue) {
        final value = saved.value;
        if (value != null) {
          _prefill(value);
        } else if (!_leaving) {
          // No such Expense (already deleted): back to the Group page.
          _leaving = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/group/$groupId');
          });
        }
      }
    } else {
      final defaultPayer = ref.watch(defaultPayerIdProvider(groupId));
      // Keeps the notifier (and its in-flight guard) alive.
      ref.watch(addExpenseProvider);
      if (!_payerReady && defaultPayer.hasValue) {
        _payerReady = true;
        _payerId = _defaultPayerId = defaultPayer.value;
      }
    }
    final saved = _saved;
    final payerNames = {for (final m in members) m.id: m.name};
    final other = _category?.needsDescription ?? false;
    final scaler = MediaQuery.textScalerOf(context);
    final metrics = _TopMetrics(
      scaler,
      payerRows: _rowsFor(members.length),
      metaLine: _isEdit,
    );
    final header = CompactTopBar(
      title: group?.name ?? '',
      onClose: _close,
      action: saved == null
          ? null
          : TopBarDangerChip(
              key: const ValueKey('delete-chip'),
              label: MessageKey.deleteChip.text,
              onTap: () => _delete(payerNames[saved.payerId] ?? ''),
            ),
    );
    if (_isEdit && saved == null) {
      // Local data only: the saved Expense arrives at once.
      return AppScaffold(header: header, body: const SizedBox.shrink());
    }

    return PopScope(
      canPop: !_hasUnsavedInput,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: AppScaffold(
        header: header,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.marginMobile,
                      vertical: metrics.regionPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AmountDisplay(buffer: _buffer),
                        if (saved != null)
                          Text(
                            _metaText(
                              saved,
                              ref.read(clockProvider).nowUtcMillis(),
                            ),
                            key: const ValueKey('edit-meta'),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.meta.copyWith(
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        Text(
                          _error?.text ?? '',
                          key: const ValueKey('amount-message'),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.message.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                        SizedBox(height: metrics.slotGap),
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

  /// "נרשם {time}", plus " · נערך {time}" once the Expense was saved with a
  /// change, both in the Expense time format.
  static String _metaText(Expense saved, int nowUtc) {
    final recorded = MessageKey.recordedMeta.fill({
      'time': formatExpenseTime(saved.createdAt, nowUtc),
    });
    if (saved.modifiedAt == saved.createdAt) return recorded;
    return recorded +
        MessageKey.editedMeta.fill({
          'time': formatExpenseTime(saved.modifiedAt, nowUtc),
        });
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
  _TopMetrics(this._scaler, {required this.payerRows, this.metaLine = false});

  final TextScaler _scaler;
  final int payerRows;

  /// Edit expense: the meta line under the Amount. Its height is paid for
  /// by tighter spacing, so Edit fits wherever Add does.
  final bool metaLine;

  /// The region's top and bottom padding.
  double get regionPadding => metaLine ? AppSpacing.s1 : AppSpacing.s3;

  /// The gap between the message slot and the payer picker.
  double get slotGap => metaLine ? AppSpacing.s1 : AppSpacing.s3;

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
      2 * regionPadding +
      _line(AppTextStyles.amountEntry) +
      (metaLine ? _line(AppTextStyles.meta) : 0) +
      _line(AppTextStyles.message) +
      slotGap +
      _payerHeight +
      AppSpacing.s4;

  /// The region's height with the 4×2 grid.
  double get gridHeight => _aboveCategories + 2 * tileHeight + AppSpacing.s2;
}
