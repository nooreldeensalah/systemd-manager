import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/utils/utils.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class LogsTab extends ConsumerStatefulWidget {
  const LogsTab({required this.unitName, super.key});

  final String unitName;

  @override
  ConsumerState<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<LogsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(unitJournalEntriesProvider(widget.unitName));

    return Column(
      children: [
        _LogsToolbar(
          onRefresh: () =>
              ref.invalidate(unitJournalEntriesProvider(widget.unitName)),
        ),
        Expanded(
          child: logsAsync.when(
            data: (logs) =>
                _LogsList(logs: logs, scrollController: _scrollController),
            loading: () => const LoadingView(),
            error: (error, stack) => ErrorView(
              message: 'Error',
              details: error.toString(),
              onRetry: () =>
                  ref.invalidate(unitJournalEntriesProvider(widget.unitName)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogsToolbar extends StatelessWidget {
  const _LogsToolbar({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          const Text(
            'Recent logs (last 100 entries)',
            style: TextStyle(fontSize: 12),
          ),
          const Spacer(),
          YaruIconButton(
            icon: const Icon(YaruIcons.refresh, size: 18),
            onPressed: onRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class _LogsList extends StatelessWidget {
  const _LogsList({required this.logs, required this.scrollController});

  final List<JournalEntry> logs;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const EmptyView(
        message: 'No logs available',
        icon: YaruIcons.document,
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final entry = logs[index];
        return _LogEntryTile(entry: entry);
      },
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = getPriorityColor(entry.priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
          left: BorderSide(color: priorityColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatTimestampCompact(entry.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.priority.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            entry.message,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
