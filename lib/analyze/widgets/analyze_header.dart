import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:yaru/yaru.dart';

class AnalyzeHeader extends ConsumerWidget {
  const AnalyzeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text('Analyze', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        YaruIconButton(
          icon: const Icon(YaruIcons.refresh),
          onPressed: () => ref.refreshAll(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}
