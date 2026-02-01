import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/analyze/widgets/widgets.dart';

class AnalyzePage extends ConsumerWidget {
  const AnalyzePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalyzeHeader(),
            SizedBox(height: 24),
            BootTimeSection(),
            SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: BlameListSection()),
                SizedBox(width: 24),
                Expanded(child: CriticalChainSection()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
