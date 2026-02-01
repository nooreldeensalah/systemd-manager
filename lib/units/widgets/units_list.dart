import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/units/unit_details_dialog.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class UnitsList extends ConsumerWidget {
  const UnitsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(filteredUnitsProvider);
    final filter = ref.watch(unitsFilterNotifierProvider);

    return unitsAsync.when(
      data: (units) {
        if (units.isEmpty) {
          return const EmptyView(message: 'No units found');
        }

        // Animate only discrete filter changes (segmented buttons / chips),
        // not every search keystroke.
        final animationKey = ValueKey(
          '${filter.stateFilter}-${filter.typeFilter}-${filter.showOnlyLoaded}',
        );

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: animationKey,
            child: ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                return UnitListItem(unit: unit);
              },
            ),
          ),
        );
      },
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(
        message: 'Failed to load units',
        details: error.toString(),
        onRetry: () => ref.invalidate(filteredUnitsProvider),
      ),
    );
  }
}

class UnitListItem extends ConsumerWidget {
  const UnitListItem({required this.unit, super.key});

  final UnitInfo unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(unitOperationsProvider);

    return UnitTile(
      unit: unit,
      onTap: () => _showUnitDetails(context),
      onStart: unit.isRunning ? null : () => _confirmAndStart(context, ref),
      onStop: unit.isRunning ? () => _confirmAndStop(context, ref) : null,
      onRestart: unit.isRunning ? () => _confirmAndRestart(context, ref) : null,
      trailing: operations.isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: YaruCircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }

  void _showUnitDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => UnitDetailsDialog(unitName: unit.name),
    );
  }

  Future<void> _confirmAndStart(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Confirm Action',
      message: 'Are you sure you want to start ${unit.name}?',
      confirmLabel: 'Start',
    );

    if (confirmed && context.mounted) {
      await ref.read(unitOperationsProvider.notifier).startUnit(unit.name);
    }
  }

  Future<void> _confirmAndStop(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Confirm Action',
      message: 'Are you sure you want to stop ${unit.name}?',
      confirmLabel: 'Stop',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      await ref.read(unitOperationsProvider.notifier).stopUnit(unit.name);
    }
  }

  Future<void> _confirmAndRestart(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Confirm Action',
      message: 'Are you sure you want to restart ${unit.name}?',
      confirmLabel: 'Restart',
    );

    if (confirmed && context.mounted) {
      await ref.read(unitOperationsProvider.notifier).restartUnit(unit.name);
    }
  }
}
