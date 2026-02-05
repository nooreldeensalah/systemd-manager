import 'package:dbus/dbus.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/services/dbus/parsers.dart';
import 'package:systemd_manager/services/systemd_service.dart';

class DBusMappers {
  static UnitInfo mapToUnitInfo(List<DBusValue> struct) {
    return UnitInfo(
      name: struct[0].asString(),
      description: struct[1].asString(),
      loadState: UnitLoadState.fromString(struct[2].asString()),
      activeState: UnitActiveState.fromString(struct[3].asString()),
      subState: struct[4].asString(),
      objectPath: struct[6].asObjectPath().value,
      jobId: struct[7].asUint32(),
      jobType: struct[8].asString(),
      jobObjectPath: struct[9].asObjectPath().value,
    );
  }

  static UnitFileInfo mapToUnitFileInfo(List<DBusValue> struct) {
    final path = struct[0].asString();
    final state = struct[1].asString();
    final name = path.split('/').last;

    return UnitFileInfo(
      path: path,
      name: name,
      state: UnitFileState.fromString(state),
    );
  }

  static UnitStatus mapToUnitStatus(
    String unitName,
    Map<String, DBusValue> props,
    Map<String, DBusValue>? serviceProps,
  ) {
    return UnitStatus(
      name: props['Id']?.asString() ?? unitName,
      description: props['Description']?.asString() ?? '',
      loadState: UnitLoadState.fromString(
        props['LoadState']?.asString() ?? 'error',
      ),
      activeState: UnitActiveState.fromString(
        props['ActiveState']?.asString() ?? 'inactive',
      ),
      subState: props['SubState']?.asString() ?? '',
      unitFileState: _parseUnitFileState(props['UnitFileState']?.asString()),
      unitFilePath: props['FragmentPath']?.asString(),
      mainPid: serviceProps?['MainPID']?.asUint32(),
      memoryBytes: DBusParsers.tryParseUint64(serviceProps?['MemoryCurrent']),
      cpuUsageMicroseconds: DBusParsers.tryParseUint64(
        serviceProps?['CPUUsageNSec'],
      ),
      activeEnterTimestamp: DBusParsers.parseTimestamp(
        props['ActiveEnterTimestamp'],
      ),
      inactiveEnterTimestamp: DBusParsers.parseTimestamp(
        props['InactiveEnterTimestamp'],
      ),
      stateChangeTimestamp: DBusParsers.parseTimestamp(
        props['StateChangeTimestamp'],
      ),
      result: serviceProps?['Result']?.asString(),
      fragmentPath: props['FragmentPath']?.asString(),
      wants: DBusParsers.parseStringList(props['Wants']),
      requires: DBusParsers.parseStringList(props['Requires']),
      wantedBy: DBusParsers.parseStringList(props['WantedBy']),
      requiredBy: DBusParsers.parseStringList(props['RequiredBy']),
      conflicts: DBusParsers.parseStringList(props['Conflicts']),
      after: DBusParsers.parseStringList(props['After']),
      before: DBusParsers.parseStringList(props['Before']),
      conditionResult: props['ConditionResult']?.asBoolean() ?? true,
      assertResult: props['AssertResult']?.asBoolean() ?? true,
      canStart: props['CanStart']?.asBoolean() ?? true,
      canStop: props['CanStop']?.asBoolean() ?? true,
      canReload: props['CanReload']?.asBoolean() ?? false,
      canIsolate: props['CanIsolate']?.asBoolean() ?? false,
      triggeredBy: DBusParsers.parseStringList(props['TriggeredBy']),
      triggers: DBusParsers.parseStringList(props['Triggers']),
      documentation: DBusParsers.parseStringList(props['Documentation']),
    );
  }

  static UnitFileState? _parseUnitFileState(String? state) {
    if (state == null || state.isEmpty) return null;
    return UnitFileState.fromString(state);
  }

  static EnableUnitResult mapToEnableUnitResult(
    DBusMethodSuccessResponse result,
  ) {
    final carries = result.returnValues[0].asBoolean();
    final changes = mapToEnableUnitChanges(result.returnValues[1]);
    return EnableUnitResult(carries: carries, changes: changes);
  }

  static List<EnableUnitChange> mapToEnableUnitChanges(DBusValue value) {
    final changes = <EnableUnitChange>[];
    for (final item in value.asArray()) {
      final struct = item.asStruct();
      changes.add(
        EnableUnitChange(
          type: struct[0].asString(),
          filename: struct[1].asString(),
          destination: struct[2].asString(),
        ),
      );
    }
    return changes;
  }
}
