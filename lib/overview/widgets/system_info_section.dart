import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:yaru/yaru.dart';

class SystemInfoSection extends ConsumerWidget {
  const SystemInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemStateAsync = ref.watch(systemStateProvider);
    final versionAsync = ref.watch(systemdVersionProvider);
    final defaultTargetAsync = ref.watch(defaultTargetProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: YaruIcons.power,
                title: 'System State',
                child: systemStateAsync.when(
                  data: (state) => _SystemStateDisplay(state: state),
                  loading: _LoadingText.new,
                  error: (e, _) => _ErrorText(message: e.toString()),
                ),
              ),
            ),
            const SizedBox(width: 24),
            const VerticalDivider(width: 1),
            const SizedBox(width: 24),
            Expanded(
              child: _InfoCard(
                icon: YaruIcons.information,
                title: 'Systemd Version',
                child: versionAsync.when(
                  data: (version) => Text(
                    version,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  loading: _LoadingText.new,
                  error: (e, _) => _ErrorText(message: e.toString()),
                ),
              ),
            ),
            const SizedBox(width: 24),
            const VerticalDivider(width: 1),
            const SizedBox(width: 24),
            Expanded(
              child: _InfoCard(
                icon: YaruIcons.target,
                title: 'Default Target',
                child: defaultTargetAsync.when(
                  data: (target) => Text(
                    target,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  loading: _LoadingText.new,
                  error: (e, _) => _ErrorText(message: e.toString()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SystemStateDisplay extends StatelessWidget {
  const _SystemStateDisplay({required this.state});

  final String state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon) = _getStateStyle(state);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          state.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  (Color, IconData) _getStateStyle(String state) {
    switch (state.toLowerCase()) {
      case 'running':
        return (Colors.green, YaruIcons.ok);
      case 'degraded':
        return (Colors.orange, YaruIcons.warning);
      case 'maintenance':
        return (Colors.blue, YaruIcons.wrench);
      case 'stopping':
        return (Colors.orange, YaruIcons.media_stop);
      case 'initializing':
        return (Colors.blue, YaruIcons.refresh);
      default:
        return (Colors.grey, YaruIcons.question);
    }
  }
}

class _LoadingText extends StatelessWidget {
  const _LoadingText();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: YaruCircularProgressIndicator(strokeWidth: 2),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
