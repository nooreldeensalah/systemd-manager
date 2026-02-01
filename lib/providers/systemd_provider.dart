import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/services/services.dart';
import 'package:systemd_manager/utils/async_action_mixin.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

part 'systemd_provider.g.dart';

@riverpod
SystemdService systemdService(Ref ref) {
  throw UnimplementedError('systemdService must be overridden');
}

@riverpod
class SystemdModeNotifier extends _$SystemdModeNotifier {
  @override
  SystemdMode build() {
    final service = ref.watch(systemdServiceProvider);
    return service.mode;
  }

  Future<void> switchMode(SystemdMode newMode) async {
    final service = ref.read(systemdServiceProvider);
    await service.switchMode(newMode);
    state = newMode;
    ref.invalidate(unitsProvider);
    ref.invalidate(unitFilesProvider);
    ref.invalidate(systemStateProvider);
  }
}

@riverpod
Future<String> systemState(Ref ref) async {
  final service = ref.watch(systemdServiceProvider);
  return service.getSystemState();
}

@riverpod
Future<String> systemdVersion(Ref ref) async {
  final service = ref.watch(systemdServiceProvider);
  return service.getVersion();
}

@riverpod
Future<String> defaultTarget(Ref ref) async {
  final service = ref.watch(systemdServiceProvider);
  return service.getDefaultTarget();
}

@riverpod
Future<List<UnitInfo>> units(Ref ref) async {
  final service = ref.watch(systemdServiceProvider);
  return service.listUnits();
}

@riverpod
Future<List<UnitInfo>> unitsByType(Ref ref, UnitType type) async {
  final service = ref.watch(systemdServiceProvider);
  return service.listUnitsByType(type);
}

@riverpod
Future<List<UnitFileInfo>> unitFiles(Ref ref) async {
  final service = ref.watch(systemdServiceProvider);
  return service.listUnitFiles();
}

@riverpod
Future<UnitStatus> unitStatus(Ref ref, String unitName) async {
  final service = ref.watch(systemdServiceProvider);
  return service.getUnitStatus(unitName);
}

@riverpod
Future<String> unitFileContent(Ref ref, String unitName) async {
  final service = ref.watch(systemdServiceProvider);
  return service.getUnitFileContent(unitName);
}

final _log = Logger('SystemdProvider');

@riverpod
class UnitOperations extends _$UnitOperations
    with AsyncNotifierActionMixin<void> {
  @override
  Logger get logger => _log;

  @override
  Future<void> build() async {
    return;
  }

  Future<void> _performUnitAction(
    String unitName,
    Future<void> Function(SystemdService s) action, {
    String? errorMsg,
    bool invalidateFiles = false,
  }) async {
    await guardAsync(() async {
      final service = ref.read(systemdServiceProvider);
      await action(service);
      ref.invalidate(unitStatusProvider(unitName));
      if (invalidateFiles) {
        ref.invalidate(unitFilesProvider);
      }
      // Always invalidate the main units list as status/state might have changed
      ref.invalidate(unitsProvider);
    }, errorMessage: errorMsg ?? 'Failed to perform action on $unitName');
  }

  Future<void> startUnit(String unitName) => _performUnitAction(
    unitName,
    (s) => s.startUnit(unitName),
    errorMsg: 'Failed to start unit $unitName',
  );

  Future<void> stopUnit(String unitName) => _performUnitAction(
    unitName,
    (s) => s.stopUnit(unitName),
    errorMsg: 'Failed to stop unit $unitName',
  );

  Future<void> restartUnit(String unitName) => _performUnitAction(
    unitName,
    (s) => s.restartUnit(unitName),
    errorMsg: 'Failed to restart unit $unitName',
  );

  Future<void> reloadUnit(String unitName) => _performUnitAction(
    unitName,
    (s) => s.reloadUnit(unitName),
    errorMsg: 'Failed to reload unit $unitName',
  );

  Future<void> enableUnit(String unitName) => _performUnitAction(
    unitName,
    (s) => s.enableUnit(unitName),
    errorMsg: 'Failed to enable unit $unitName',
    invalidateFiles: true,
  );

  Future<void> disableUnit(String unitName) => _performUnitAction(
    unitName,
    (s) => s.disableUnit(unitName),
    errorMsg: 'Failed to disable unit $unitName',
    invalidateFiles: true,
  );

  Future<void> maskUnit(String unitName) => _performUnitAction(
    unitName,
    (s) => s.maskUnit(unitName),
    errorMsg: 'Failed to mask unit $unitName',
    invalidateFiles: true,
  );

  Future<void> unmaskUnit(String unitName) => _performUnitAction(
    unitName,
    (s) => s.unmaskUnit(unitName),
    errorMsg: 'Failed to unmask unit $unitName',
    invalidateFiles: true,
  );

  Future<void> daemonReload() async {
    await guardAsync(() async {
      final service = ref.read(systemdServiceProvider);
      await service.daemonReload();
      ref.invalidate(unitsProvider);
      ref.invalidate(unitFilesProvider);
    }, errorMessage: 'Failed to reload daemon');
  }

  Future<void> resetFailed([String? unitName]) async {
    await guardAsync(() async {
      final service = ref.read(systemdServiceProvider);
      await service.resetFailedUnit(unitName);
      ref.invalidate(unitsProvider);
      if (unitName != null) {
        ref.invalidate(unitStatusProvider(unitName));
      }
    }, errorMessage: 'Failed to reset failed state');
  }
}
