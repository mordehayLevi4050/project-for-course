import 'package:flutter/material.dart';

import '../../i18n/isolate_name.dart';
import '../../i18n/message_key.dart';
import '../theme/tokens.dart';
import 'app_sheet.dart';

/// The Active-group sheet (FR-7, FR-8): offers to make a Group the Active
/// group. When another Group is active, [currentActiveName] names it in the
/// warning strip "הקבוצה '{name}' תפסיק להיות הקבוצה הפעילה".
///
/// Resolves to `true` on "כן, להפוך לפעילה" and `null` when dismissed
/// ("לא עכשיו", the scrim or system back). It writes nothing itself.
Future<bool?> showActiveGroupSheet(
  BuildContext context, {
  String? currentActiveName,
}) => showAppSheet<bool>(
  context,
  builder: (context) => AppSheetLayout(
    title: MessageKey.activeSheetTitle.text,
    body: Text(
      MessageKey.activeSheetBody.text,
      style: AppTextStyles.message.copyWith(color: AppColors.ink),
    ),
    warning: currentActiveName == null
        ? null
        : MessageKey.activeSheetWarning.fill({
            'name': isolateName(currentActiveName),
          }),
    primary: FilledButton(
      onPressed: () => Navigator.of(context).pop(true),
      child: Text(MessageKey.activeSheetConfirm.text),
    ),
    secondary: OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(MessageKey.activeSheetDecline.text),
    ),
  ),
);
