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

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;

  late final AnimationController _transitionController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (final route in AppRoute.values)
        KeyedSubtree(
          key: PageStorageKey<String>('route:${route.name}'),
          child: route.buildPage(context, ref),
        ),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              if (index == _selectedIndex) return;
              setState(() {
                _previousIndex = _selectedIndex;
                _selectedIndex = index;
              });
              _transitionController.forward(from: 0);
            },
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
            child: AnimatedBuilder(
              animation: _transitionController,
              builder: (context, _) {
                final isAnimating = _transitionController.isAnimating;

                double clamp01(double t) => t < 0 ? 0.0 : (t > 1 ? 1.0 : t);

                // Material 3 top-level destinations: fade-through.
                // Outgoing fades quickly, incoming fades in with a slight delay.
                final t = _transitionController.value;
                final outgoingOpacity = isAnimating
                    ? 1.0 - Curves.easeIn.transform(clamp01(t / 0.35))
                    : 0.0;
                final incomingOpacity = isAnimating
                    ? Curves.easeOut.transform(clamp01((t - 0.15) / 0.85))
                    : 1.0;

                return Stack(
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      Offstage(
                        offstage:
                            !(i == _selectedIndex ||
                                (isAnimating && i == _previousIndex)),
                        child: TickerMode(
                          enabled: i == _selectedIndex,
                          child: IgnorePointer(
                            ignoring: i != _selectedIndex,
                            child: Opacity(
                              opacity: i == _selectedIndex
                                  ? incomingOpacity
                                  : outgoingOpacity,
                              child: pages[i],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
