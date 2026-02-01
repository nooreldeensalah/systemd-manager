import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/analyze/analyze_page.dart';
import 'package:systemd_manager/journal/journal_page.dart';
import 'package:systemd_manager/overview/overview_page.dart';
import 'package:systemd_manager/units/units_page.dart';

enum AppRoute { overview, units, journal, analyze }

extension AppRouteExtension on AppRoute {
  Widget buildPage(BuildContext context, WidgetRef ref) {
    return switch (this) {
      AppRoute.overview => const OverviewPage(),
      AppRoute.units => const UnitsPage(),
      AppRoute.journal => const JournalPage(),
      AppRoute.analyze => const AnalyzePage(),
    };
  }

  String get path => '/$name';
}
