import 'package:flutter/widgets.dart';

import '../../i18n/message_key.dart';
import 'confirm_sheet.dart';

/// The Exit sheet (FR-10): "לצאת ללא שמירה?" with "מה שהזנת לא יישמר.",
/// the danger "יציאה" and "המשך עריכה".
///
/// Resolves to `true` on "יציאה" and `null` when dismissed ("המשך עריכה",
/// the scrim or system back), which keeps the input intact.
Future<bool?> showExitSheet(BuildContext context) => showConfirmSheet(
  context,
  title: MessageKey.exitTitle.text,
  body: MessageKey.exitBody.text,
  confirmLabel: MessageKey.exitConfirm.text,
  cancelLabel: MessageKey.keepEditing.text,
);
