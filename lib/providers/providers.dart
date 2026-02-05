library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/providers/analyze_provider.dart';
import 'package:systemd_manager/providers/systemd_provider.dart';
import 'package:systemd_manager/providers/units_provider.dart';

export 'analyze_provider.dart';
export 'journal_provider.dart';
export 'systemd_provider.dart';
export 'units_provider.dart';

extension SystemdRefX on Ref {
  void refreshAll() {
    invalidate(systemStateProvider);
    invalidate(systemdVersionProvider);
    invalidate(unitsProvider);
    invalidate(unitFilesProvider);
    invalidate(defaultTargetProvider);
    invalidate(unitCountsProvider);
    invalidate(bootTimingsProvider);
  }
}

extension SystemdWidgetRefX on WidgetRef {
  void refreshAll() {
    invalidate(systemStateProvider);
    invalidate(systemdVersionProvider);
    invalidate(unitsProvider);
    invalidate(unitFilesProvider);
    invalidate(defaultTargetProvider);
    invalidate(unitCountsProvider);
    invalidate(bootTimingsProvider);
  }
}
