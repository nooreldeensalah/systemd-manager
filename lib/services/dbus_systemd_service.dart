import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/services/dbus/constants.dart';
import 'package:systemd_manager/services/dbus/mappers.dart';
import 'package:systemd_manager/services/systemd_service.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

final _log = Logger('DBusSystemdService');

class DBusSystemdService implements SystemdService {
  DBusSystemdService();

  DBusClient? _systemBus;
  DBusClient? _sessionBus;
  DBusClient? _activeBus;
  DBusRemoteObject? _manager;
  SystemdMode _mode = SystemdMode.system;
  bool _isConnected = false;

  ServiceErrorListener? _errorListener;
  ServiceStateListener? _stateListener;

  bool _systemBusSubscribed = false;
  bool _sessionBusSubscribed = false;

  Future<void> _connectionQueue = Future.value();

  final _unitChangedController = StreamController<String>.broadcast();
  final _jobCompletedController =
      StreamController<JobCompletedEvent>.broadcast();
  StreamSubscription<DBusSignal>? _unitChangedSubscription;
  StreamSubscription<DBusSignal>? _jobCompletedSubscription;

  @override
  SystemdMode get mode => _mode;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> connect({SystemdMode mode = SystemdMode.system}) async {
    await _enqueueConnectionOp(() => _connectInternal(mode));
  }

  Future<void> _connectInternal(SystemdMode mode) async {
    if (_isConnected && _mode == mode) return;

    if (_isConnected && _mode != mode) {
      await _disconnectInternal();
    }

    _mode = mode;

    try {
      if (mode == SystemdMode.system) {
        _systemBus ??= DBusClient.system();
        _activeBus = _systemBus;
      } else {
        _sessionBus ??= DBusClient.session();
        _activeBus = _sessionBus;
      }

      _manager = DBusRemoteObject(
        _activeBus!,
        name: DBusConstants.systemdBusName,
        path: DBusObjectPath(DBusConstants.systemdObjectPath),
      );

      await _subscribeToSignals();

      _isConnected = true;
      _stateListener?.call();
      _log.info('Connected to systemd D-Bus ($mode mode)');
    } on Exception catch (e, stack) {
      _notifyError(e, stack);
      await _disconnectInternal();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _enqueueConnectionOp(() async {
      await _disconnectInternal();
      _stateListener?.call();
    });
  }

  @override
  Future<void> switchMode(SystemdMode newMode) async {
    if (newMode == _mode) return;

    await _enqueueConnectionOp(() async {
      _log.info('Switching systemd D-Bus mode: $_mode -> $newMode');

      await _disconnectInternal();
      await _connectInternal(newMode);
    });
  }

  Future<T> _enqueueConnectionOp<T>(Future<T> Function() action) {
    final future = _connectionQueue.then((_) => action());
    _connectionQueue = future.then((_) => null, onError: (_) => null);
    return future;
  }

  Future<void> _disconnectInternal() async {
    await _unitChangedSubscription?.cancel();
    _unitChangedSubscription = null;
    await _jobCompletedSubscription?.cancel();
    _jobCompletedSubscription = null;

    await _unsubscribeFromSignals();

    _manager = null;
    _activeBus = null;
    _isConnected = false;
    _log.info('Disconnected from systemd D-Bus');
  }

  Future<void> _subscribeToSignals() async {
    await _unitChangedSubscription?.cancel();
    _unitChangedSubscription = null;
    await _jobCompletedSubscription?.cancel();
    _jobCompletedSubscription = null;

    final signalStream = DBusSignalStream(
      _activeBus!,
      sender: DBusConstants.systemdBusName,
      interface: DBusConstants.managerInterface,
    );

    _unitChangedSubscription = signalStream.listen((signal) {
      if (signal.name == 'UnitNew' || signal.name == 'UnitRemoved') {
        if (signal.values.isNotEmpty) {
          final unitName = signal.values[0].asString();
          _unitChangedController.add(unitName);
        }
      } else if (signal.name == 'JobRemoved') {
        if (signal.values.length >= 4) {
          final id = signal.values[0].asUint32();
          final unitName = signal.values[2].asString();
          final result = signal.values[3].asString();
          _jobCompletedController.add(
            JobCompletedEvent(id: id, unitName: unitName, result: result),
          );
        }
      }
    });

    final bus = _activeBus;
    if (bus == null || _manager == null) {
      throw StateError('No active D-Bus connection');
    }

    if (!_isSubscribedForBus(bus)) {
      try {
        await _manager!.callMethod(
          DBusConstants.managerInterface,
          'Subscribe',
          [],
          replySignature: DBusSignature(''),
        );
        _setSubscribedForBus(bus, true);
      } on DBusMethodResponseException catch (e) {
        if (e.errorName == 'org.freedesktop.systemd1.AlreadySubscribed') {
          _setSubscribedForBus(bus, true);
          _log.debug('Already subscribed to systemd signals; continuing.');
        } else {
          rethrow;
        }
      }
    }
  }

  Future<void> _unsubscribeFromSignals() async {
    final bus = _activeBus;
    final manager = _manager;
    if (bus == null || manager == null) return;

    if (!_isSubscribedForBus(bus)) return;

    try {
      await manager.callMethod(
        DBusConstants.managerInterface,
        'Unsubscribe',
        [],
        replySignature: DBusSignature(''),
      );
    } on DBusMethodResponseException catch (e, stack) {
      _log.debug('Unsubscribe failed: ${e.errorName}', e, stack);
    } finally {
      _setSubscribedForBus(bus, false);
    }
  }

  bool _isSubscribedForBus(DBusClient bus) {
    if (identical(bus, _systemBus)) return _systemBusSubscribed;
    if (identical(bus, _sessionBus)) return _sessionBusSubscribed;
    return false;
  }

  void _setSubscribedForBus(DBusClient bus, bool value) {
    if (identical(bus, _systemBus)) {
      _systemBusSubscribed = value;
    } else if (identical(bus, _sessionBus)) {
      _sessionBusSubscribed = value;
    }
  }

  void _checkConnected() {
    if (!_isConnected || _manager == null) {
      throw StateError('Not connected to systemd D-Bus');
    }
  }

  @override
  Future<List<UnitInfo>> listUnits() async {
    _checkConnected();

    final result = await _manager!.callMethod(
      DBusConstants.managerInterface,
      'ListUnits',
      [],
      replySignature: DBusSignature('a(ssssssouso)'),
    );

    return result.returnValues[0]
        .asArray()
        .map((item) => DBusMappers.mapToUnitInfo(item.asStruct()))
        .toList();
  }

  @override
  Future<List<UnitInfo>> listUnitsByType(UnitType type) async {
    final allUnits = await listUnits();
    return allUnits.where((u) => u.type == type).toList();
  }

  @override
  Future<List<UnitFileInfo>> listUnitFiles() async {
    _checkConnected();

    final result = await _manager!.callMethod(
      DBusConstants.managerInterface,
      'ListUnitFiles',
      [],
      replySignature: DBusSignature('a(ss)'),
    );

    return result.returnValues[0]
        .asArray()
        .map((item) => DBusMappers.mapToUnitFileInfo(item.asStruct()))
        .toList();
  }

  @override
  Future<List<UnitFileInfo>> listUnitFilesByType(UnitType type) async {
    final allFiles = await listUnitFiles();
    return allFiles.where((u) => u.type == type).toList();
  }

  @override
  Future<UnitStatus> getUnitStatus(String unitName) async {
    _checkConnected();

    final loadResult = await _manager!.callMethod(
      DBusConstants.managerInterface,
      'LoadUnit',
      [DBusString(unitName)],
      replySignature: DBusSignature('o'),
    );

    final unitPath = loadResult.returnValues[0].asObjectPath();
    final unitObject = DBusRemoteObject(
      _activeBus!,
      name: DBusConstants.systemdBusName,
      path: unitPath,
    );

    final propsResult = await unitObject.callMethod(
      DBusConstants.propertiesInterface,
      'GetAll',
      [const DBusString(DBusConstants.unitInterface)],
      replySignature: DBusSignature('a{sv}'),
    );

    final props = <String, DBusValue>{};
    for (final entry in propsResult.returnValues[0].asDict().entries) {
      props[entry.key.asString()] = entry.value.asVariant();
    }

    Map<String, DBusValue>? serviceProps;
    if (unitName.endsWith('.service')) {
      try {
        final serviceResult = await unitObject.callMethod(
          DBusConstants.propertiesInterface,
          'GetAll',
          [const DBusString(DBusConstants.serviceInterface)],
          replySignature: DBusSignature('a{sv}'),
        );
        serviceProps = {};
        for (final entry in serviceResult.returnValues[0].asDict().entries) {
          serviceProps[entry.key.asString()] = entry.value.asVariant();
        }
      } on DBusMethodResponseException catch (e) {
        _log.debug('Could not fetch service properties for $unitName: $e');
      }
    }

    return DBusMappers.mapToUnitStatus(unitName, props, serviceProps);
  }

  @override
  Future<UnitActiveState> getUnitActiveState(String unitName) async {
    final status = await getUnitStatus(unitName);
    return status.activeState;
  }

  @override
  Future<UnitFileState> getUnitFileState(String unitName) async {
    _checkConnected();

    final result = await _manager!.callMethod(
      DBusConstants.managerInterface,
      'GetUnitFileState',
      [DBusString(unitName)],
      replySignature: DBusSignature('s'),
    );

    return UnitFileState.fromString(result.returnValues[0].asString());
  }

  @override
  Future<bool> isUnitActive(String unitName) async {
    final state = await getUnitActiveState(unitName);
    return state.isRunning;
  }

  @override
  Future<bool> isUnitEnabled(String unitName) async {
    final state = await getUnitFileState(unitName);
    return state.isEnabled;
  }

  Future<void> _callUnitMethod(
    String method,
    String unitName, {
    String mode = 'replace',
  }) async {
    _checkConnected();
    _log.info('$method unit: $unitName (mode: $mode)');
    await _manager!.callMethod(DBusConstants.managerInterface, method, [
      DBusString(unitName),
      DBusString(mode),
    ], replySignature: DBusSignature('o'));
  }

  @override
  Future<void> startUnit(String unitName, {String mode = 'replace'}) =>
      _callUnitMethod('StartUnit', unitName, mode: mode);

  @override
  Future<void> stopUnit(String unitName, {String mode = 'replace'}) =>
      _callUnitMethod('StopUnit', unitName, mode: mode);

  @override
  Future<void> restartUnit(String unitName, {String mode = 'replace'}) =>
      _callUnitMethod('RestartUnit', unitName, mode: mode);

  @override
  Future<void> reloadUnit(String unitName, {String mode = 'replace'}) =>
      _callUnitMethod('ReloadUnit', unitName, mode: mode);

  @override
  Future<void> reloadOrRestartUnit(
    String unitName, {
    String mode = 'replace',
  }) => _callUnitMethod('ReloadOrRestartUnit', unitName, mode: mode);

  @override
  Future<void> killUnit(
    String unitName, {
    String who = 'all',
    int signal = 15,
  }) async {
    _checkConnected();
    _log.info('Killing unit: $unitName (who: $who, signal: $signal)');
    await _manager!.callMethod(DBusConstants.managerInterface, 'KillUnit', [
      DBusString(unitName),
      DBusString(who),
      DBusInt32(signal),
    ], replySignature: DBusSignature(''));
  }

  @override
  Future<void> resetFailedUnit([String? unitName]) async {
    _checkConnected();
    _log.info('Resetting failed state: ${unitName ?? "all units"}');
    if (unitName != null) {
      await _manager!.callMethod(
        DBusConstants.managerInterface,
        'ResetFailedUnit',
        [DBusString(unitName)],
        replySignature: DBusSignature(''),
      );
    } else {
      await _manager!.callMethod(
        DBusConstants.managerInterface,
        'ResetFailed',
        [],
        replySignature: DBusSignature(''),
      );
    }
  }

  @override
  Future<EnableUnitResult> enableUnit(
    String unitName, {
    bool runtime = false,
    bool force = false,
  }) async {
    _checkConnected();
    _log.info('Enabling unit: $unitName (runtime: $runtime, force: $force)');

    final result = await _manager!.callMethod(
      DBusConstants.managerInterface,
      'EnableUnitFiles',
      [
        DBusArray.string([unitName]),
        DBusBoolean(runtime),
        DBusBoolean(force),
      ],
      replySignature: DBusSignature('ba(sss)'),
    );

    return DBusMappers.mapToEnableUnitResult(result);
  }

  @override
  Future<EnableUnitResult> disableUnit(
    String unitName, {
    bool runtime = false,
  }) async {
    _checkConnected();
    _log.info('Disabling unit: $unitName (runtime: $runtime)');

    final result = await _manager!.callMethod(
      DBusConstants.managerInterface,
      'DisableUnitFiles',
      [
        DBusArray.string([unitName]),
        DBusBoolean(runtime),
      ],
      replySignature: DBusSignature('a(sss)'),
    );

    return EnableUnitResult(
      carries: false,
      changes: DBusMappers.mapToEnableUnitChanges(result.returnValues[0]),
    );
  }

  @override
  Future<EnableUnitResult> maskUnit(
    String unitName, {
    bool runtime = false,
  }) async {
    _checkConnected();
    _log.info('Masking unit: $unitName (runtime: $runtime)');

    final result = await _manager!.callMethod(
      DBusConstants.managerInterface,
      'MaskUnitFiles',
      [
        DBusArray.string([unitName]),
        DBusBoolean(runtime),
        const DBusBoolean(true),
      ],
      replySignature: DBusSignature('a(sss)'),
    );

    return EnableUnitResult(
      carries: false,
      changes: DBusMappers.mapToEnableUnitChanges(result.returnValues[0]),
    );
  }

  @override
  Future<EnableUnitResult> unmaskUnit(
    String unitName, {
    bool runtime = false,
  }) async {
    _checkConnected();
    _log.info('Unmasking unit: $unitName (runtime: $runtime)');

    final result = await _manager!.callMethod(
      DBusConstants.managerInterface,
      'UnmaskUnitFiles',
      [
        DBusArray.string([unitName]),
        DBusBoolean(runtime),
      ],
      replySignature: DBusSignature('a(sss)'),
    );

    return EnableUnitResult(
      carries: false,
      changes: DBusMappers.mapToEnableUnitChanges(result.returnValues[0]),
    );
  }

  @override
  Future<String> getUnitFileContent(String unitName) async {
    final path = await getUnitFilePath(unitName);
    if (path.isEmpty) return '';

    final file = File(path);
    if (!await file.exists()) {
      _log.warning('Unit file not found at path: $path for unit: $unitName');
      return '';
    }

    return file.readAsString();
  }

  @override
  Future<String> getUnitFilePath(String unitName) async {
    final status = await getUnitStatus(unitName);
    return status.fragmentPath ?? '';
  }

  @override
  Future<void> daemonReload() async {
    _checkConnected();
    _log.info('Reloading systemd daemon');

    await _manager!.callMethod(
      DBusConstants.managerInterface,
      'Reload',
      [],
      replySignature: DBusSignature(''),
    );
  }

  @override
  Future<void> daemonReexec() async {
    _checkConnected();
    _log.info('Re-executing systemd daemon');

    await _manager!.callMethod(
      DBusConstants.managerInterface,
      'Reexecute',
      [],
      replySignature: DBusSignature(''),
    );
  }

  @override
  Future<List<String>> getUnitRequires(String unitName) async {
    final status = await getUnitStatus(unitName);
    return status.requires;
  }

  @override
  Future<List<String>> getUnitWants(String unitName) async {
    final status = await getUnitStatus(unitName);
    return status.wants;
  }

  @override
  Future<List<String>> getUnitRequiredBy(String unitName) async {
    final status = await getUnitStatus(unitName);
    return status.requiredBy;
  }

  @override
  Future<List<String>> getUnitWantedBy(String unitName) async {
    final status = await getUnitStatus(unitName);
    return status.wantedBy;
  }

  @override
  Future<List<String>> getUnitBefore(String unitName) async {
    final status = await getUnitStatus(unitName);
    return status.before;
  }

  @override
  Future<List<String>> getUnitAfter(String unitName) async {
    final status = await getUnitStatus(unitName);
    return status.after;
  }

  @override
  Future<List<String>> getUnitConflicts(String unitName) async {
    final status = await getUnitStatus(unitName);
    return status.conflicts;
  }

  @override
  Future<String> getSystemState() async {
    _checkConnected();

    final result = await _manager!
        .callMethod(DBusConstants.propertiesInterface, 'Get', [
          const DBusString(DBusConstants.managerInterface),
          const DBusString('SystemState'),
        ], replySignature: DBusSignature('v'));

    return result.returnValues[0].asVariant().asString();
  }

  @override
  Future<String> getDefaultTarget() async {
    _checkConnected();

    final result = await _manager!.callMethod(
      DBusConstants.managerInterface,
      'GetDefaultTarget',
      [],
      replySignature: DBusSignature('s'),
    );

    return result.returnValues[0].asString();
  }

  @override
  void registerErrorListener(ServiceErrorListener listener) {
    _errorListener = listener;
  }

  @override
  void removeErrorListener() {
    _errorListener = null;
  }

  @override
  void registerStateListener(ServiceStateListener listener) {
    _stateListener = listener;
  }

  @override
  void removeStateListener() {
    _stateListener = null;
  }

  @override
  Stream<String> subscribeToUnitChanges() => _unitChangedController.stream;

  @override
  Stream<JobCompletedEvent> subscribeToJobCompleted() =>
      _jobCompletedController.stream;

  @override
  Future<void> setDefaultTarget(String targetName) async {
    _checkConnected();
    await _manager!.callMethod(
      DBusConstants.managerInterface,
      'SetDefaultTarget',
      [DBusString(targetName), const DBusBoolean(true)], // force=true
      replySignature: DBusSignature('o'),
    );
  }

  @override
  Future<String> getVersion() async {
    _checkConnected();
    final result = await _manager!
        .callMethod(DBusConstants.propertiesInterface, 'Get', [
          const DBusString(DBusConstants.managerInterface),
          const DBusString('Version'),
        ], replySignature: DBusSignature('v'));
    return result.returnValues[0].asVariant().asString();
  }

  @override
  Future<List<String>> getFeatures() async {
    _checkConnected();
    final result = await _manager!
        .callMethod(DBusConstants.propertiesInterface, 'Get', [
          const DBusString(DBusConstants.managerInterface),
          const DBusString('Features'),
        ], replySignature: DBusSignature('v'));
    return result.returnValues[0].asVariant().asString().split(' ');
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _unitChangedController.close();
    await _jobCompletedController.close();
  }

  void _notifyError(Exception error, StackTrace stack) {
    _errorListener?.call(error, stack);
    _log.error('DBus systemd service error', error, stack);
  }
}
