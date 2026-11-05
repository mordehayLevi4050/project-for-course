import 'dart:async';

import 'package:go_router/go_router.dart';

import '../features/expenses/ui/add_expense_screen.dart';
import '../features/expenses/ui/group_page.dart';
import '../features/groups/ui/archive_screen.dart';
import '../features/groups/ui/create_group_screen.dart';
import '../features/groups/ui/group_list_screen.dart';
import '../features/groups/ui/group_settings_screen.dart';
import '../features/settle_up/ui/summary_screen.dart';

/// Answers whether the Group [id] is an Archived group (for the redirect).
typedef IsGroupArchived = Future<bool> Function(String id);

/// The app's only router (AD-16). Every route uses a `NoTransitionPage`.
///
/// `/create`, `/group/:id` and `/archive` are children of `/`, so back from
/// any of them leads to the group list. Create group leaves with
/// `go('/group/:id')`, which replaces it with the new Group's page.
/// `add`, `edit/:eid`, `settings` and `summary` are children of `group/:id`,
/// so leaving Add or Edit expense, Group settings or the Summary returns to
/// the Group page. An archived card opens
/// `/archive/group/:id`, so back from it returns to the Archive view; its
/// Summary is `/archive/group/:id/summary`, whose back returns to that
/// archived page.
///
/// [isArchived] drives the redirect that keeps Add expense, Edit expense and
/// Group settings of an Archived group out of reach: it opens
/// the Group's read-only page instead. `group/:id/summary` of an Archived
/// group redirects to `/archive/group/:id/summary`. Read-only mode itself
/// comes from `isGroupMutable` on the page, never from the route.
GoRouter buildRouter({
  String initialLocation = '/',
  required IsGroupArchived isArchived,
}) {
  FutureOr<String?> archivedRedirect(GoRouterState state) async {
    final id = state.pathParameters['id']!;
    return await isArchived(id) ? '/archive/group/$id' : null;
  }

  FutureOr<String?> archivedSummaryRedirect(GoRouterState state) async {
    final id = state.pathParameters['id']!;
    return await isArchived(id) ? '/archive/group/$id/summary' : null;
  }

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const GroupListScreen(),
        ),
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
            routes: [
              GoRoute(
                path: 'add',
                redirect: (context, state) => archivedRedirect(state),
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: AddExpenseScreen(groupId: state.pathParameters['id']!),
                ),
              ),
              GoRoute(
                path: 'edit/:eid',
                redirect: (context, state) => archivedRedirect(state),
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: AddExpenseScreen(
                    groupId: state.pathParameters['id']!,
                    expenseId: state.pathParameters['eid'],
                  ),
                ),
              ),
              GoRoute(
                path: 'settings',
                redirect: (context, state) => archivedRedirect(state),
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: GroupSettingsScreen(
                    groupId: state.pathParameters['id']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'summary',
                redirect: (context, state) => archivedSummaryRedirect(state),
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: SummaryScreen(groupId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'archive',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ArchiveScreen(),
            ),
            routes: [
              GoRoute(
                path: 'group/:id',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: GroupPage(groupId: state.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'summary',
                    pageBuilder: (context, state) => NoTransitionPage(
                      key: state.pageKey,
                      child: SummaryScreen(
                        groupId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
