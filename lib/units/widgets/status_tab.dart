import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/utils/utils.dart';
import 'package:systemd_manager/widgets/widgets.dart';

class StatusTab extends ConsumerWidget {
  const StatusTab({required this.unitName, super.key});

  final String unitName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(unitStatusProvider(unitName));

    return statusAsync.when(
      data: (status) => _StatusContent(status: status),
      loading: () => const LoadingView(),
      error: (error, stack) => ErrorView(
        message: 'Error',
        details: error.toString(),
        onRetry: () => ref.invalidate(unitStatusProvider(unitName)),
      ),
    );
  }
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({required this.status});

  final UnitStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.fromUnitStatus(status, size: StatusBadgeSize.large),
              const SizedBox(width: 12),
              EnableBadge(
                state: status.unitFileState,
                size: StatusBadgeSize.large,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (status.description.isNotEmpty) ...[
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(status.description),
            const SizedBox(height: 16),
          ],
          _StatusGrid(status: status),
          if (_hasDependencies(status)) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _DependenciesSection(status: status),
          ],
          if (status.documentation.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text('Documentation', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...status.documentation.map(
              (doc) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SelectableText(
                  doc,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasDependencies(UnitStatus status) {
    return status.requires.isNotEmpty ||
        status.wants.isNotEmpty ||
        status.requiredBy.isNotEmpty ||
        status.wantedBy.isNotEmpty ||
        status.after.isNotEmpty ||
        status.before.isNotEmpty;
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({required this.status});

  final UnitStatus status;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(), 1: FlexColumnWidth(2)},
      children: [
        _buildRow('Load State', status.loadState.name),
        _buildRow(
          'Active State',
          '${status.activeState.name} (${status.subState})',
        ),
        if (status.mainPid != null && status.mainPid! > 0)
          _buildRow('Main PID', status.mainPid.toString()),
        if (status.memoryBytes != null)
          _buildRow('Memory', status.memoryDisplay),
        if (status.activeEnterTimestamp != null)
          _buildRow(
            'Since',
            formatTimestampWithRelative(status.activeEnterTimestamp!),
          ),
        if (status.isRunning && status.uptime != null)
          _buildRow('Uptime', status.uptimeDisplay),
        if (status.serviceType != null) _buildRow('Type', status.serviceType!),
        if (status.restart != null) _buildRow('Restart', status.restart!),
        if (status.result != null && status.result != 'success')
          _buildRow('Result', status.result!),
        if (status.fragmentPath != null)
          _buildRow('Unit File', status.fragmentPath!),
      ],
    );
  }

  TableRow _buildRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SelectableText(value),
        ),
      ],
    );
  }
}

class _DependenciesSection extends StatelessWidget {
  const _DependenciesSection({required this.status});

  final UnitStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dependencies', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            if (status.requires.isNotEmpty)
              _DependencyList(title: 'Requires', units: status.requires),
            if (status.wants.isNotEmpty)
              _DependencyList(title: 'Wants', units: status.wants),
            if (status.requiredBy.isNotEmpty)
              _DependencyList(title: 'Required By', units: status.requiredBy),
            if (status.wantedBy.isNotEmpty)
              _DependencyList(title: 'Wanted By', units: status.wantedBy),
            if (status.after.isNotEmpty)
              _DependencyList(title: 'After', units: status.after),
            if (status.before.isNotEmpty)
              _DependencyList(title: 'Before', units: status.before),
            if (status.conflicts.isNotEmpty)
              _DependencyList(title: 'Conflicts', units: status.conflicts),
          ],
        ),
      ],
    );
  }
}

class _DependencyList extends StatelessWidget {
  const _DependencyList({required this.title, required this.units});

  final String title;
  final List<String> units;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          ...units
              .take(5)
              .map(
                (unit) => Text(
                  unit,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          if (units.length > 5)
            Text(
              '... and ${units.length - 5} more',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
