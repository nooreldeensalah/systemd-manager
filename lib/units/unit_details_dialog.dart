import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/units/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class UnitDetailsDialog extends ConsumerWidget {
  const UnitDetailsDialog({required this.unitName, super.key});

  final String unitName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              _DialogHeader(unitName: unitName),
              const TabBar(
                tabs: [
                  Tab(text: 'Status'),
                  Tab(text: 'Unit File'),
                  Tab(text: 'Logs'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    StatusTab(unitName: unitName),
                    UnitFileTab(unitName: unitName),
                    LogsTab(unitName: unitName),
                  ],
                ),
              ),
              ActionButtons(unitName: unitName),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.unitName});

  final String unitName;

  @override
  Widget build(BuildContext context) {
    return YaruDialogTitleBar(
      title: Text(unitName, overflow: TextOverflow.ellipsis),
      actions: [
        YaruIconButton(
          icon: const Icon(YaruIcons.window_close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Close',
        ),
      ],
    );
  }
}
