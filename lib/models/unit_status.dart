import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:systemd_manager/models/unit_type.dart';
import 'package:systemd_manager/utils/formatters.dart';

part 'unit_status.freezed.dart';
part 'unit_status.g.dart';

@freezed
class UnitStatus with _$UnitStatus {
  const factory UnitStatus({
    required String name,

    required String description,

    required UnitLoadState loadState,

    required UnitActiveState activeState,

    required String subState,

    UnitFileState? unitFileState,

    String? unitFilePath,

    int? mainPid,

    int? memoryBytes,

    int? cpuUsageMicroseconds,

    DateTime? activeEnterTimestamp,

    DateTime? inactiveEnterTimestamp,

    DateTime? stateChangeTimestamp,

    String? user,

    String? group,

    String? restart,

    String? serviceType,

    int? execMainCode,

    int? execMainStatus,

    String? result,

    String? fragmentPath,

    String? sourcePath,

    @Default([]) List<String> wants,

    @Default([]) List<String> requires,

    @Default([]) List<String> wantedBy,

    @Default([]) List<String> requiredBy,

    @Default([]) List<String> conflicts,

    @Default([]) List<String> after,

    @Default([]) List<String> before,

    @Default(true) bool conditionResult,

    @Default(true) bool assertResult,

    @Default(true) bool canStart,

    @Default(true) bool canStop,

    @Default(false) bool canReload,

    @Default(false) bool canIsolate,

    @Default([]) List<String> triggeredBy,

    @Default([]) List<String> triggers,

    @Default([]) List<String> documentation,
  }) = _UnitStatus;

  const UnitStatus._();

  factory UnitStatus.fromJson(Map<String, dynamic> json) =>
      _$UnitStatusFromJson(json);

  UnitType? get type => UnitType.fromUnitName(name);

  String get baseName {
    final type = this.type;
    if (type != null) {
      return name.substring(0, name.length - type.suffix.length - 1);
    }
    return name;
  }

  bool get isRunning => activeState.isRunning;

  bool get isFailed => activeState.isFailed;

  bool get isInactive => activeState.isInactive;

  bool get isEnabled => unitFileState?.isEnabled ?? false;

  String get memoryDisplay {
    if (memoryBytes == null) return '-';
    return formatBytes(memoryBytes!);
  }

  Duration? get uptime {
    if (activeEnterTimestamp == null || !isRunning) return null;
    return DateTime.now().difference(activeEnterTimestamp!);
  }

  String get uptimeDisplay => formatUptime(uptime);
}
