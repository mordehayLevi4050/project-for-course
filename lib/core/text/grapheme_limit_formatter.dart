import 'package:flutter/services.dart';

import 'names.dart';

/// Blocks input beyond [maxLength] grapheme clusters (FR-1, FR-2).
///
/// Typing past the limit is ignored. A paste that would exceed it is cut so
/// that only the first [maxLength] grapheme clusters are kept.
class GraphemeLimitFormatter extends TextInputFormatter {
  GraphemeLimitFormatter(this.maxLength) : assert(maxLength > 0);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (graphemeLength(newValue.text) <= maxLength) return newValue;
    if (graphemeLength(oldValue.text) >= maxLength &&
        oldValue.selection.isCollapsed) {
      // Already full and nothing selected to replace: the extra input is
      // ignored, wherever the cursor is.
      return oldValue;
    }
    final text = truncateGraphemes(newValue.text, maxLength);
    final offset = newValue.selection.baseOffset.clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
