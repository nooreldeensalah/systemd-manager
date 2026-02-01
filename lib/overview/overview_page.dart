import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/overview/widgets/widgets.dart';

class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OverviewHeader(),
            SizedBox(height: 24),
            SystemInfoSection(),
            SizedBox(height: 24),
            UnitStatisticsSection(),
            SizedBox(height: 24),
            QuickActionsSection(),
            SizedBox(height: 24),
            FailedUnitsSection(),
          ],
        ),
      ),
    );
  }
}
