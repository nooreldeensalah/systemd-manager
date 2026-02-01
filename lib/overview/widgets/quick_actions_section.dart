import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class QuickActionsSection extends ConsumerWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(unitOperationsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionButton(
              icon: YaruIcons.refresh,
              label: 'Daemon Reload',
              tooltip: 'Reload systemd manager configuration',
              isLoading: operations.isLoading,
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context: context,
                  title: 'Confirm Action',
                  message:
                      'Are you sure you want to reload the systemd daemon?',
                );
                if (confirmed && context.mounted) {
                  await ref
                      .read(unitOperationsProvider.notifier)
                      .daemonReload();
                }
              },
            ),
            _ActionButton(
              icon: YaruIcons.undo,
              label: 'Reset Failed',
              tooltip: 'Reset failed state for all units',
              isLoading: operations.isLoading,
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context: context,
                  title: 'Confirm Action',
                  message:
                      'Are you sure you want to reset failed state for all units?',
                );
                if (confirmed && context.mounted) {
                  await ref.read(unitOperationsProvider.notifier).resetFailed();
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: YaruCircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(label),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}
