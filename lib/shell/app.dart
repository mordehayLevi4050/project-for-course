import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/i18n/message_key.dart';
import '../core/ui/theme/app_theme.dart';

/// The largest text scale the layout supports (NFR-4, AD-21).
const double maxTextScale = 1.5;

/// The fixed app locale (AD-14).
const Locale appLocale = Locale('he');

/// The root widget: Hebrew, RTL, light theme, text scale clamped to 1.5.
class GrouPayApp extends StatelessWidget {
  const GrouPayApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (_) => MessageKey.appName.text,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: ThemeMode.light,
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxTextScale,
        child: child!,
      ),
    );
  }
}
