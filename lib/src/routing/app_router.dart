import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_providers.dart';
import '../features/connections/presentation/connections_page.dart';
import '../features/groups/presentation/groups_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/shell/presentation/sterminal_shell.dart';
import '../features/snippets/presentation/snippets_page.dart';
import '../features/terminal/presentation/terminal_page.dart';
import '../features/vault/presentation/vault_page.dart';
import 'app_route.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNavigator',
);
final _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellNavigator',
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final windowArguments = ref.watch(windowArgumentsProvider);
  final initialLocation = windowArguments.shouldStartInTerminal
      ? '/terminal/${windowArguments.hostId!}'
      : '/connections';
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return SterminalShell(state: state, child: child);
        },
        routes: [
          GoRoute(
            path: '/connections',
            name: AppRoute.connections.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ConnectionsPage()),
          ),
          GoRoute(
            path: '/groups',
            name: AppRoute.groups.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GroupsPage()),
          ),
          GoRoute(
            path: '/snippets',
            name: AppRoute.snippets.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SnippetsPage()),
          ),
          GoRoute(
            path: '/vault',
            name: AppRoute.vault.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VaultPage()),
          ),
          GoRoute(
            path: '/settings',
            name: AppRoute.settings.name,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/terminal/:hostId',
        name: AppRoute.terminal.name,
        builder: (context, state) {
          final hostId = state.pathParameters['hostId']!;
          return TerminalPage(hostId: hostId);
        },
      ),
    ],
  );
});
