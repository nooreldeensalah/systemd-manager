import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/units/widgets/widgets.dart';

class UnitsPage extends ConsumerWidget {
  const UnitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Column(
        children: [
          UnitsHeader(),
          Divider(height: 1),
          Expanded(child: UnitsList()),
        ],
      ),
    );
  }
}
