import 'package:go_router/go_router.dart';

import '../features/groups/ui/group_list_screen.dart';

/// The app's only router (AD-16). Every route uses a `NoTransitionPage`.
GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const GroupListScreen()),
    ),
  ],
);
