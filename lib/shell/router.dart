import 'package:go_router/go_router.dart';

import '../features/groups/ui/create_group_screen.dart';
import '../features/groups/ui/group_list_screen.dart';
import '../features/groups/ui/group_page.dart';

/// The app's only router (AD-16). Every route uses a `NoTransitionPage`.
///
/// `/create` and `/group/:id` are children of `/`, so back from either leads
/// to the group list. Create group leaves with `go('/group/:id')`, which
/// replaces it with the new Group's page.
GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const GroupListScreen()),
      routes: [
        GoRoute(
          path: 'create',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const CreateGroupScreen(),
          ),
        ),
        GoRoute(
          path: 'group/:id',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: GroupPage(groupId: state.pathParameters['id']!),
          ),
        ),
      ],
    ),
  ],
);
