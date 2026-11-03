import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/message_key.dart';
import '../../text/grapheme_limit_formatter.dart';
import '../theme/tokens.dart';

/// A name text field (FR-1, FR-2, FR-3, FR-5): blocks input beyond
/// [maxLength] grapheme clusters, shows the [error] inline under the field,
/// and submits on the keyboard action without dropping focus.
///
/// With [onAdd] it carries the teal "+" button on the end side, inside the
/// field (the add-member field).
class NameField extends StatelessWidget {
  const NameField({
    super.key,
    required this.controller,
    required this.maxLength,
    required this.onSubmit,
    this.focusNode,
    this.hint,
    this.error,
    this.onChanged,
    this.onAdd,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final int maxLength;
  final String? hint;
  final MessageKey? error;
  final ValueChanged<String>? onChanged;
  final VoidCallback onSubmit;
  final VoidCallback? onAdd;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final onAdd = this.onAdd;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      style: AppTextStyles.rowTitle.copyWith(color: AppColors.ink),
      inputFormatters: <TextInputFormatter>[GraphemeLimitFormatter(maxLength)],
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      // Handling editing-complete here keeps the focus and the keyboard.
      onEditingComplete: onSubmit,
      decoration: InputDecoration(
        hintText: hint,
        errorText: error?.text,
        errorMaxLines: 2,
        constraints: const BoxConstraints(minHeight: AppSizes.textFieldHeight),
        suffixIcon: onAdd == null ? null : _AddButton(onTap: onAdd),
      ),
    );
  }
}

/// The 36dp teal "+" with a 48dp hit area.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('name-field-add'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: AppSizes.minTouchTarget,
        child: Center(
          child: Container(
            width: AppSizes.inlineAddButton,
            height: AppSizes.inlineAddButton,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.headerEnd,
              shape: BoxShape.circle,
            ),
            child: Text(
              MessageKey.addMemberButton.text,
              style: AppTextStyles.screenTitle.copyWith(
                color: AppColors.onHeader,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
