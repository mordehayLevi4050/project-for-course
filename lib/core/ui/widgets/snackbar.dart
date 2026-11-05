import 'package:flutter/material.dart';

import '../../i18n/message_key.dart';

/// The app's [ScaffoldMessenger], set on `MaterialApp` by `shell/`, so a
/// snackbar survives the route change from Edit expense to the Group page.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>(debugLabel: 'appMessenger');

/// Shows [message] in the snackbar (DESIGN.md › Snackbar): a floating
/// `ink` pill with white text above the Group page bottom bar (the theme's
/// `snackBarTheme`). It disappears by itself and has no action, so no undo.
/// Used only for "ההוצאה נמחקה".
void showAppSnackbar(MessageKey message) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message.text)));
}
