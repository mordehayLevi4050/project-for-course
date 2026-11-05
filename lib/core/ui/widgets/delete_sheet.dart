import 'package:flutter/widgets.dart';

import '../../i18n/message_key.dart';
import 'confirm_sheet.dart';

/// The Delete sheet (FR-14): "למחוק את ההוצאה?", the expense [line]
/// ("🛒 אוכל ושתייה · מוטי · ₪87.4", built with `MessageKey.expenseLine`),
/// "אי אפשר לבטל את הפעולה.", the danger "מחיקה" and "ביטול".
///
/// Resolves to `true` on "מחיקה" and `null` when dismissed ("ביטול", the
/// scrim or system back), which changes nothing. Every delete goes through
/// it; the caller runs the delete.
Future<bool?> showDeleteSheet(BuildContext context, {required String line}) =>
    showConfirmSheet(
      context,
      title: MessageKey.deleteTitle.text,
      body: line,
      detail: MessageKey.deleteBody.text,
      confirmLabel: MessageKey.deleteConfirm.text,
    );
