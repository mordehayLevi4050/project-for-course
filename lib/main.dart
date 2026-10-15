import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/json_storage.dart';
import 'screens/groups_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(JsonStorage())..load();
  runApp(GroupayApp(state: state));
}

class GroupayApp extends StatelessWidget {
  final AppState state;

  const GroupayApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        title: 'GrouPay',
        debugShowCheckedModeBanner: false,
        theme: buildGroupayTheme(),
        // Hebrew only: this also makes the whole layout right-to-left.
        locale: const Locale('he'),
        supportedLocales: const [Locale('he')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const GroupsScreen(),
      ),
    );
  }
}
