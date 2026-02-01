import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/utils/utils.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class LogListView extends StatefulWidget {
  const LogListView({
    required this.logs,
    required this.scrollController,
    this.autoScroll = false,
    super.key,
  });

  final List<JournalEntry> logs;
  final ScrollController scrollController;
  final bool autoScroll;

  @override
  State<LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<LogListView> {
  @override
  void didUpdateWidget(LogListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll && widget.logs.length > oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollController.hasClients) {
          widget.scrollController.animateTo(
            widget.scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.logs.isEmpty) {
      return const EmptyView(
        message: 'No log entries found',
        icon: YaruIcons.document,
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Text(
                '${widget.logs.length} entries',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(YaruIcons.copy, size: 18),
                onPressed: () => _copyAllLogs(context),
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: widget.logs.length,
            itemBuilder: (context, index) {
              final entry = widget.logs[index];
              return LogEntryTile(entry: entry);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _copyAllLogs(BuildContext context) async {
    final buffer = StringBuffer();
    for (final entry in widget.logs) {
      buffer.writeln(
        '${entry.fullTimestampDisplay} [${entry.priority.displayName}] ${entry.source}: ${entry.message}',
      );
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class LogEntryTile extends StatelessWidget {
  const LogEntryTile({required this.entry, super.key});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = getPriorityColor(entry.priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: entry.priority.isError
            ? priorityColor.withValues(alpha: 0.05)
            : null,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
          left: BorderSide(color: priorityColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                entry.fullTimestampDisplay,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  entry.priority.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.source,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              if (entry.pid != null) ...[
                const SizedBox(width: 8),
                Text(
                  '[${entry.pid}]',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            entry.message,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: entry.priority.isError
                  ? priorityColor
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
