import 'package:flutter/material.dart';

import '../../../core/i18n/message_key.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/ui/theme/tokens.dart';

/// The custom amount keypad (DESIGN.md › Keypad): keys 1–9, `.`, 0 and ⌫ in
/// LTR digit order, 3×4, with no "00" key. Each key is at least 48dp tall.
/// What a press does to the Amount is decided only by `core/money`
/// (`pressKeypadKey`).
class Keypad extends StatelessWidget {
  const Keypad({super.key, required this.onKey});

  final ValueChanged<KeypadKey> onKey;

  static const List<List<KeypadKey>> _rows = [
    [KeypadKey.digit1, KeypadKey.digit2, KeypadKey.digit3],
    [KeypadKey.digit4, KeypadKey.digit5, KeypadKey.digit6],
    [KeypadKey.digit7, KeypadKey.digit8, KeypadKey.digit9],
    [KeypadKey.decimalPoint, KeypadKey.digit0, KeypadKey.backspace],
  ];

  @override
  Widget build(BuildContext context) {
    // Digits keep the LTR phone order inside the RTL layout.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, row) in _rows.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.s2),
            Row(
              children: [
                for (final (j, key) in row.indexed) ...[
                  if (j > 0) const SizedBox(width: AppSpacing.s2),
                  Expanded(
                    child: _Key(keypadKey: key, onTap: () => onKey(key)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.keypadKey, required this.onTap});

  final KeypadKey keypadKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = keypadKey == KeypadKey.backspace
        ? MessageKey.keypadBackspace.text
        : keypadKey.symbol;
    return GestureDetector(
      key: ValueKey('keypad-${keypadKey.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.keypadKeyHeight),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.surfaceBase,
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
        ),
        child: Text(
          label,
          style: AppTextStyles.keypadDigit.copyWith(color: AppColors.ink),
        ),
      ),
    );
  }
}
