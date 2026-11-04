import 'package:flutter/widgets.dart';

import '../core/db/app_database.dart';
import 'bootstrap.dart';

/// The app entry point (AD-21). `lib/main.dart` re-exports it.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await buildGrouPay(AppDatabase.open()));
}
