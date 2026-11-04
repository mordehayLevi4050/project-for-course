import 'package:flutter/material.dart';

import '../../i18n/message_key.dart';
import '../theme/tokens.dart';
import 'app_sheet.dart';

/// The confirm button of destructive sheets (`components.button-danger`):
/// the primary pill in danger red, with no glow.
final ButtonStyle dangerButtonStyle = FilledButton.styleFrom(
  backgroundColor: AppColors.danger,
  foregroundColor: AppColors.onDanger,
  shadowColor: Colors.transparent,
  elevation: 0,
);

/// A confirmation sheet: the [title], an optional [body], the [confirmLabel]
/// button on the start side and the [cancelLabel] (default "ביטול") beside
/// it.
///
/// When [destructive] (Remove member; later Delete and Exit) the confirm is
/// the danger button; otherwise (Archive) it is the orange primary.
///
/// Resolves to `true` when confirmed and `null` when dismissed ("ביטול", the
/// scrim or system back). It writes nothing itself: the caller runs the
/// action, whose policy check stays in the repository transaction.
Future<bool?> showConfirmSheet(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? body,
  String? cancelLabel,
  bool destructive = true,
}) => showAppSheet<bool>(
  context,
  builder: (context) => AppSheetLayout(
    title: title,
    body: body == null
        ? null
        : Text(
            body,
            style: AppTextStyles.message.copyWith(color: AppColors.ink),
          ),
    primary: FilledButton(
      style: destructive ? dangerButtonStyle : null,
      onPressed: () => Navigator.of(context).pop(true),
      child: Text(confirmLabel),
    ),
    secondary: OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(cancelLabel ?? MessageKey.cancel.text),
    ),
  ),
);
