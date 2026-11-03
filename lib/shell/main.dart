import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart';
import 'app.dart';
import 'overrides.dart';
import 'router.dart';

/// The app entry point (AD-21). `lib/main.dart` re-exports it.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase.open();
  runApp(
    ProviderScope(
      overrides: appOverrides(database: database),
      child: GrouPayApp(router: buildRouter()),
    ),
  );
}
