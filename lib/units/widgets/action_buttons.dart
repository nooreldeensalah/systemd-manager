import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class ActionButtons extends ConsumerWidget {
  const ActionButtons({required this.unitName, super.key});

  final String unitName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(unitStatusProvider(unitName));
    final operations = ref.watch(unitOperationsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: statusAsync.when(
        data: (status) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (status.unitFileState != null) ...[
              if (status.isEnabled)
                OutlinedButton.icon(
                  icon: const Icon(YaruIcons.checkbox),
                  label: const Text('Disable'),
                  onPressed: operations.isLoading
                      ? null
                      : () => _confirmAndDisable(context, ref),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(YaruIcons.checkbox_checked),
                  label: const Text('Enable'),
                  onPressed: operations.isLoading
                      ? null
                      : () => _confirmAndEnable(context, ref),
                ),
              const SizedBox(width: 8),
            ],
            if (status.isRunning && status.canStop)
              OutlinedButton.icon(
                icon: const Icon(YaruIcons.media_stop),
                label: const Text('Stop'),
                onPressed: operations.isLoading
                    ? null
                    : () => _confirmAndStop(context, ref),
              ),
            if (!status.isRunning && status.canStart)
              FilledButton.icon(
                icon: const Icon(YaruIcons.media_play),
                label: const Text('Start'),
                onPressed: operations.isLoading
                    ? null
                    : () => _confirmAndStart(context, ref),
              ),
            if (status.isRunning) ...[
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(YaruIcons.refresh),
                label: const Text('Restart'),
                onPressed: operations.isLoading
                    ? null
                    : () => _confirmAndRestart(context, ref),
              ),
            ],
            if (operations.isLoading) ...[
              const SizedBox(width: 16),
              const SizedBox(
                width: 20,
                height: 20,
                child: YaruCircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Future<void> _confirmAndStart(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Confirm Action',
      message: 'Are you sure you want to start $unitName?',
      confirmLabel: 'Start',
    );

    if (confirmed && context.mounted) {
      await ref.read(unitOperationsProvider.notifier).startUnit(unitName);
    }
  }

  Future<void> _confirmAndStop(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Confirm Action',
      message: 'Are you sure you want to stop $unitName?',
      confirmLabel: 'Stop',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      await ref.read(unitOperationsProvider.notifier).stopUnit(unitName);
    }
  }

  Future<void> _confirmAndRestart(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Confirm Action',
      message: 'Are you sure you want to restart $unitName?',
      confirmLabel: 'Restart',
    );

    if (confirmed && context.mounted) {
      await ref.read(unitOperationsProvider.notifier).restartUnit(unitName);
    }
  }

  Future<void> _confirmAndEnable(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Confirm Action',
      message: 'Are you sure you want to enable $unitName?',
      confirmLabel: 'Enable',
    );

    if (confirmed && context.mounted) {
      await ref.read(unitOperationsProvider.notifier).enableUnit(unitName);
    }
  }

  Future<void> _confirmAndDisable(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Confirm Action',
      message: 'Are you sure you want to disable $unitName?',
      confirmLabel: 'Disable',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      await ref.read(unitOperationsProvider.notifier).disableUnit(unitName);
    }
  }
}
