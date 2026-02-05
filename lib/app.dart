import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/routes.dart';
import 'package:yaru/yaru.dart';

class SystemdManagerApp extends ConsumerWidget {
  const SystemdManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          title: 'Systemd Manager',
          debugShowCheckedModeBanner: false,
          theme: yaru.theme,
          darkTheme: yaru.darkTheme,
          highContrastTheme: yaruHighContrastLight,
          highContrastDarkTheme: yaruHighContrastDark,
          home: const AppShell(),
        );
      },
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    YaruIcons.settings,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Systemd',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(YaruIcons.window),
                selectedIcon: Icon(YaruIcons.window_filled),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(YaruIcons.app_grid),
                selectedIcon: Icon(YaruIcons.ubuntu_logo_simple),
                label: Text('Units'),
              ),
              NavigationRailDestination(
                icon: Icon(YaruIcons.document),
                selectedIcon: Icon(YaruIcons.document_filled),
                label: Text('Journal'),
              ),
              NavigationRailDestination(
                icon: Icon(YaruIcons.meter_0),
                selectedIcon: Icon(YaruIcons.meter_3),
                label: Text('Analyze'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                for (final route in AppRoute.values)
                  KeyedSubtree(
                    key: PageStorageKey('route:${route.name}'),
                    child: route.buildPage(context, ref),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
