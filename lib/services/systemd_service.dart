import 'package:systemd_manager/models/models.dart';

typedef ServiceErrorListener =
    void Function(Exception error, StackTrace? stack);

typedef ServiceStateListener = void Function();

enum SystemdMode { system, user }

class EnableUnitResult {
  const EnableUnitResult({required this.carries, required this.changes});

  final bool carries;
  final List<EnableUnitChange> changes;
}

class EnableUnitChange {
  const EnableUnitChange({
    required this.type,
    required this.filename,
    required this.destination,
  });

  final String type;
  final String filename;
  final String destination;
}

abstract class SystemdService {
  SystemdMode get mode;

  bool get isConnected;

  Future<void> connect({SystemdMode mode = SystemdMode.system});

  Future<void> disconnect();

  Future<void> switchMode(SystemdMode newMode);

  Future<List<UnitInfo>> listUnits();

  Future<List<UnitInfo>> listUnitsByType(UnitType type);

  Future<List<UnitFileInfo>> listUnitFiles();

  Future<List<UnitFileInfo>> listUnitFilesByType(UnitType type);

  Future<UnitStatus> getUnitStatus(String unitName);

  Future<UnitActiveState> getUnitActiveState(String unitName);

  Future<UnitFileState> getUnitFileState(String unitName);

  Future<bool> isUnitActive(String unitName);

  Future<bool> isUnitEnabled(String unitName);

  Future<void> startUnit(String unitName, {String mode = 'replace'});

  Future<void> stopUnit(String unitName, {String mode = 'replace'});

  Future<void> restartUnit(String unitName, {String mode = 'replace'});

  Future<void> reloadUnit(String unitName, {String mode = 'replace'});

  Future<void> reloadOrRestartUnit(String unitName, {String mode = 'replace'});

  Future<void> killUnit(String unitName, {String who = 'all', int signal = 15});

  Future<void> resetFailedUnit([String? unitName]);

  Future<EnableUnitResult> enableUnit(
    String unitName, {
    bool runtime = false,
    bool force = false,
  });

  Future<EnableUnitResult> disableUnit(String unitName, {bool runtime = false});

  Future<EnableUnitResult> maskUnit(String unitName, {bool runtime = false});

  Future<EnableUnitResult> unmaskUnit(String unitName, {bool runtime = false});

  Future<String> getUnitFileContent(String unitName);

  Future<String> getUnitFilePath(String unitName);

  Future<void> daemonReload();

  Future<void> daemonReexec();

  Future<List<String>> getUnitRequires(String unitName);

  Future<List<String>> getUnitWants(String unitName);

  Future<List<String>> getUnitRequiredBy(String unitName);

  Future<List<String>> getUnitWantedBy(String unitName);

  Future<List<String>> getUnitBefore(String unitName);

  Future<List<String>> getUnitAfter(String unitName);

  Future<List<String>> getUnitConflicts(String unitName);

  Future<String> getSystemState();

  Future<String> getDefaultTarget();

  Future<void> setDefaultTarget(String targetName);

  Future<String> getVersion();

  Future<List<String>> getFeatures();

  Stream<String> subscribeToUnitChanges();

  Stream<JobCompletedEvent> subscribeToJobCompleted();

  void registerErrorListener(ServiceErrorListener listener);

  void removeErrorListener();

  void registerStateListener(ServiceStateListener listener);

  void removeStateListener();

  Future<void> dispose();
}

class JobCompletedEvent {
  const JobCompletedEvent({
    required this.id,
    required this.unitName,
    required this.result,
  });

  final int id;

  final String unitName;

  final String result;

  bool get isSuccess => result == 'done';
}
