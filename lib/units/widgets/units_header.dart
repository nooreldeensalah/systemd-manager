import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/services/services.dart';
import 'package:yaru/yaru.dart';

class UnitsHeader extends ConsumerWidget {
  const UnitsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(unitsFilterNotifierProvider);
    final countsAsync = ref.watch(unitCountsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Units', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 16),
              countsAsync.when(
                data: (counts) => Text(
                  '${counts.total} units (${counts.active} active, ${counts.failed} failed)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Spacer(),
              const ModeToggle(),
              const SizedBox(width: 8),
              YaruIconButton(
                icon: const Icon(YaruIcons.refresh),
                onPressed: () => ref.invalidate(unitsProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 300,
                height: 40,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search units...',
                    prefixIcon: Icon(YaruIcons.search, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    ref
                        .read(unitsFilterNotifierProvider.notifier)
                        .setSearchQuery(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              SegmentedButton<UnitStateFilter>(
                segments: const [
                  ButtonSegment(value: UnitStateFilter.all, label: Text('All')),
                  ButtonSegment(
                    value: UnitStateFilter.active,
                    label: Text('Active'),
                  ),
                  ButtonSegment(
                    value: UnitStateFilter.inactive,
                    label: Text('Inactive'),
                  ),
                  ButtonSegment(
                    value: UnitStateFilter.failed,
                    label: Text('Failed'),
                  ),
                ],
                selected: {filter.stateFilter},
                onSelectionChanged: (selection) {
                  ref
                      .read(unitsFilterNotifierProvider.notifier)
                      .setStateFilter(selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TypeFilterChip(
                  label: 'All Units',
                  type: null,
                  selected: filter.typeFilter == null,
                ),
                const SizedBox(width: 8),
                TypeFilterChip(
                  label: 'Services',
                  type: UnitType.service,
                  selected: filter.typeFilter == UnitType.service,
                ),
                const SizedBox(width: 8),
                TypeFilterChip(
                  label: 'Timers',
                  type: UnitType.timer,
                  selected: filter.typeFilter == UnitType.timer,
                ),
                const SizedBox(width: 8),
                TypeFilterChip(
                  label: 'Sockets',
                  type: UnitType.socket,
                  selected: filter.typeFilter == UnitType.socket,
                ),
                const SizedBox(width: 8),
                TypeFilterChip(
                  label: 'Targets',
                  type: UnitType.target,
                  selected: filter.typeFilter == UnitType.target,
                ),
                const SizedBox(width: 8),
                TypeFilterChip(
                  label: 'Mounts',
                  type: UnitType.mount,
                  selected: filter.typeFilter == UnitType.mount,
                ),
                const SizedBox(width: 8),
                TypeFilterChip(
                  label: 'Devices',
                  type: UnitType.device,
                  selected: filter.typeFilter == UnitType.device,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ModeToggle extends ConsumerWidget {
  const ModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(systemdModeNotifierProvider);

    return SegmentedButton<SystemdMode>(
      segments: const [
        ButtonSegment(
          value: SystemdMode.system,
          label: Text('System'),
          icon: Icon(YaruIcons.computer, size: 16),
        ),
        ButtonSegment(
          value: SystemdMode.user,
          label: Text('User'),
          icon: Icon(YaruIcons.user, size: 16),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) async {
        try {
          await ref
              .read(systemdModeNotifierProvider.notifier)
              .switchMode(selection.first);
        } on Object catch (_) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to D-Bus')),
          );
        }
      },
    );
  }
}

class TypeFilterChip extends ConsumerWidget {
  const TypeFilterChip({
    required this.label,
    required this.type,
    required this.selected,
    super.key,
  });

  final String label;
  final UnitType? type;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        ref
            .read(unitsFilterNotifierProvider.notifier)
            .setTypeFilter(value ? type : null);
      },
    );
  }
}
