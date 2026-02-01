import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/models/boot_timings.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class BlameListSection extends ConsumerWidget {
  const BlameListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timingsAsync = ref.watch(bootTimingsProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(YaruIcons.clock, size: 20),
                const SizedBox(width: 8),
                Text('Slowest Units', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Units sorted by startup time (systemd-analyze blame)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            timingsAsync.when(
              data: (timings) {
                if (timings.blame.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No blame data available')),
                  );
                }

                final topBlame = timings.blame.take(15).toList();

                return Column(
                  children: topBlame.asMap().entries.map((entry) {
                    final index = entry.key;
                    final blame = entry.value;
                    return _BlameEntryTile(
                      blame: blame,
                      index: index + 1,
                      maxTime: timings.blame.first.time,
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: LoadingView(),
              ),
              error: (error, _) => ErrorView(
                message: 'Error',
                details: error.toString(),
                onRetry: () => ref.invalidate(bootTimingsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlameEntryTile extends StatelessWidget {
  const _BlameEntryTile({
    required this.blame,
    required this.index,
    required this.maxTime,
  });

  final BlameEntry blame;
  final int index;
  final Duration maxTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = maxTime.inMilliseconds > 0
        ? blame.time.inMilliseconds / maxTime.inMilliseconds
        : 0.0;

    final color =
        Color.lerp(Colors.green, Colors.red, percentage) ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#$index',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  blame.timeDisplay,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  blame.unitName,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: YaruLinearProgressIndicator(
                value: percentage,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
