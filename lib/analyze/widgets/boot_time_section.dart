import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/models/boot_timings.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class BootTimeSection extends ConsumerWidget {
  const BootTimeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timingsAsync = ref.watch(bootTimingsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: timingsAsync.when(
          data: (timings) => _BootTimeContent(timings: timings),
          loading: () =>
              const Padding(padding: EdgeInsets.all(32), child: LoadingView()),
          error: (error, _) => ErrorView(
            message: 'Error',
            details: error.toString(),
            onRetry: () => ref.invalidate(bootTimingsProvider),
          ),
        ),
      ),
    );
  }
}

class _BootTimeContent extends StatelessWidget {
  const _BootTimeContent({required this.timings});

  final BootTimings timings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(YaruIcons.clock, size: 24),
            const SizedBox(width: 12),
            Text('Boot Time', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Text(
                timings.totalTimeDisplay,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                'Total',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _BootTimeBar(timings: timings),
        const SizedBox(height: 24),
        _BootTimeGrid(timings: timings),
      ],
    );
  }
}

class _BootTimeBar extends StatelessWidget {
  const _BootTimeBar({required this.timings});

  final BootTimings timings;

  @override
  Widget build(BuildContext context) {
    final total = timings.totalTime.inMilliseconds.toDouble();
    if (total <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Boot timeline', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (timings.firmwareTime != null)
                  _TimeSegment(
                    flex: timings.firmwareTime!.inMilliseconds,
                    color: Colors.purple,
                    label: 'Firmware',
                  ),
                if (timings.loaderTime != null)
                  _TimeSegment(
                    flex: timings.loaderTime!.inMilliseconds,
                    color: Colors.indigo,
                    label: 'Loader',
                  ),
                _TimeSegment(
                  flex: timings.kernelTime.inMilliseconds,
                  color: Colors.blue,
                  label: 'Kernel',
                ),
                if (timings.initrdTime != null)
                  _TimeSegment(
                    flex: timings.initrdTime!.inMilliseconds,
                    color: Colors.teal,
                    label: 'Initrd',
                  ),
                _TimeSegment(
                  flex: timings.userspaceTime.inMilliseconds,
                  color: Colors.green,
                  label: 'Userspace',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (timings.firmwareTime != null)
              const _LegendItem(color: Colors.purple, label: 'Firmware'),
            if (timings.loaderTime != null)
              const _LegendItem(color: Colors.indigo, label: 'Loader'),
            const _LegendItem(color: Colors.blue, label: 'Kernel'),
            if (timings.initrdTime != null)
              const _LegendItem(color: Colors.teal, label: 'Initrd'),
            const _LegendItem(color: Colors.green, label: 'Userspace'),
          ],
        ),
      ],
    );
  }
}

class _TimeSegment extends StatelessWidget {
  const _TimeSegment({
    required this.flex,
    required this.color,
    required this.label,
  });

  final int flex;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (flex <= 0) return const SizedBox.shrink();

    return Expanded(
      flex: flex,
      child: Tooltip(
        message: label,
        child: Container(color: color),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _BootTimeGrid extends StatelessWidget {
  const _BootTimeGrid({required this.timings});

  final BootTimings timings;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 32,
      runSpacing: 16,
      children: [
        if (timings.firmwareTime != null)
          _TimeCard(
            label: 'Firmware',
            duration: timings.firmwareTime!,
            color: Colors.purple,
          ),
        if (timings.loaderTime != null)
          _TimeCard(
            label: 'Loader',
            duration: timings.loaderTime!,
            color: Colors.indigo,
          ),
        _TimeCard(
          label: 'Kernel',
          duration: timings.kernelTime,
          color: Colors.blue,
        ),
        if (timings.initrdTime != null)
          _TimeCard(
            label: 'Initrd',
            duration: timings.initrdTime!,
            color: Colors.teal,
          ),
        _TimeCard(
          label: 'Userspace',
          duration: timings.userspaceTime,
          color: Colors.green,
        ),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.duration,
    required this.color,
  });

  final String label;
  final Duration duration;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            _formatDuration(duration),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    }
    final seconds = duration.inMilliseconds / 1000;
    return '${seconds.toStringAsFixed(2)}s';
  }
}
