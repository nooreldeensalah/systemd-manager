import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/services/services.dart';
import 'package:yaru/yaru.dart';

class OverviewHeader extends ConsumerWidget {
  const OverviewHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(systemdModeNotifierProvider);

    return Row(
      children: [
        Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                mode == SystemdMode.system
                    ? YaruIcons.computer
                    : YaruIcons.user,
                size: 16,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                mode == SystemdMode.system ? 'System' : 'User',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(YaruIcons.refresh),
          onPressed: () {
            ref.invalidate(systemStateProvider);
            ref.invalidate(systemdVersionProvider);
            ref.invalidate(unitCountsProvider);
            ref.invalidate(unitsProvider);
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}
