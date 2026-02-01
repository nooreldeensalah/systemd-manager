import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class UnitStatisticsSection extends ConsumerWidget {
  const UnitStatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(unitCountsProvider);

    return countsAsync.when(
      data: (counts) => Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Total Units',
              count: counts.total,
              icon: YaruIcons.document,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: 'Active',
              count: counts.active,
              icon: YaruIcons.ok_simple,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: 'Inactive',
              count: counts.inactive,
              icon: YaruIcons.media_stop,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCard(
              title: 'Failed',
              count: counts.failed,
              icon: YaruIcons.error,
              color: Colors.red,
              highlighted: counts.failed > 0,
            ),
          ),
        ],
      ),
      loading: () => Row(
        children: List.generate(
          4,
          (index) => const Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: YaruCircularProgressIndicator()),
              ),
            ),
          ),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorView(
            message: 'Failed to load units',
            details: error.toString(),
            onRetry: () => ref.invalidate(unitCountsProvider),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.highlighted = false,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: highlighted ? color.withValues(alpha: 0.1) : theme.cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                if (highlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Attention',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              count.toString(),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
