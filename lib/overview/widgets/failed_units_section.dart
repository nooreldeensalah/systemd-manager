import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/utils/utils.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class FailedUnitsSection extends ConsumerWidget {
  const FailedUnitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(YaruIcons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text('Failed Units', style: theme.textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: unitsAsync.when(
            data: (units) {
              final failedUnits = units
                  .where((u) => u.activeState.isFailed)
                  .toList();

              if (failedUnits.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(YaruIcons.ok, size: 48, color: Colors.green),
                        const SizedBox(height: 12),
                        Text(
                          'No failed units',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All units are operating normally',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: failedUnits.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final unit = failedUnits[index];
                  return _FailedUnitTile(unit: unit);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: LoadingView()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: ErrorView(
                message: 'Failed to load units',
                details: error.toString(),
                onRetry: () => ref.invalidate(unitsProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FailedUnitTile extends ConsumerWidget {
  const _FailedUnitTile({required this.unit});

  final UnitInfo unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final operations = ref.watch(unitOperationsProvider);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(getUnitTypeIcon(unit.type), color: Colors.red, size: 20),
      ),
      title: Text(
        unit.name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        unit.description.isNotEmpty ? unit.description : unit.subState,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: operations.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: YaruCircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(YaruIcons.undo, size: 18),
            onPressed: operations.isLoading
                ? null
                : () => _resetFailed(context, ref),
            tooltip: 'Reset failed state',
          ),
          IconButton(
            icon: const Icon(YaruIcons.refresh, size: 18),
            onPressed: operations.isLoading
                ? null
                : () => _restart(context, ref),
            tooltip: 'Restart',
          ),
        ],
      ),
    );
  }

  Future<void> _resetFailed(BuildContext context, WidgetRef ref) async {
    await ref.read(unitOperationsProvider.notifier).resetFailed(unit.name);
  }

  Future<void> _restart(BuildContext context, WidgetRef ref) async {
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
