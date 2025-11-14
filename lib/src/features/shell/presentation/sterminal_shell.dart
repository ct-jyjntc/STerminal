import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sterminal/src/l10n/l10n.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class SterminalShell extends StatelessWidget {
  const SterminalShell({
    super.key,
    required this.child,
    required this.state,
  });

  final Widget child;
  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    final destinations = _buildDestinations(context);
    final width = MediaQuery.of(context).size.width;
    final selectedIndex = _indexForLocation(state.matchedLocation, destinations);
    final useRail = width >= 900;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 88,
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  Expanded(
                    child: NavigationRail(
                      selectedIndex: selectedIndex,
                      backgroundColor: Colors.transparent,
                      onDestinationSelected: (index) {
                        context.go(destinations[index].route);
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final destination in destinations)
                          NavigationRailDestination(
                            icon: Icon(destination.icon),
                            label: Text(destination.label),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          context.go(destinations[index].route);
        },
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }

  List<ShellDestination> _buildDestinations(BuildContext context) {
    final l10n = context.l10n;
    return [
      ShellDestination(
        label: l10n.connectionsTitle,
        icon: Icons.dns_outlined,
        route: '/connections',
      ),
      ShellDestination(
        label: l10n.groupsTitle,
        icon: Icons.layers_outlined,
        route: '/groups',
      ),
      ShellDestination(
        label: l10n.snippetsTitle,
        icon: Icons.code_outlined,
        route: '/snippets',
      ),
      ShellDestination(
        label: l10n.vaultTitle,
        icon: Icons.vpn_key_outlined,
        route: '/vault',
      ),
      ShellDestination(
        label: l10n.settingsTitle,
        icon: Icons.settings_outlined,
        route: '/settings',
      ),
    ];
  }

  int _indexForLocation(String location, List<ShellDestination> destinations) {
    final matchIndex = destinations.indexWhere(
      (destination) => location.startsWith(destination.route),
    );
    return matchIndex >= 0 ? matchIndex : 0;
  }
}
