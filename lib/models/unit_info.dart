import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:systemd_manager/models/unit_type.dart';

part 'unit_info.freezed.dart';
part 'unit_info.g.dart';

@freezed
class UnitInfo with _$UnitInfo {
  const factory UnitInfo({
    required String name,

    required String description,

    required UnitLoadState loadState,

    required UnitActiveState activeState,

    required String subState,

    required String objectPath,

    @Default(0) int jobId,

    @Default('') String jobType,

    @Default('') String jobObjectPath,
  }) = _UnitInfo;

  const UnitInfo._();

  factory UnitInfo.fromJson(Map<String, dynamic> json) =>
      _$UnitInfoFromJson(json);

  UnitType? get type => UnitType.fromUnitName(name);

  String get baseName => switch (type) {
    final type? => name.substring(0, name.length - type.suffix.length - 1),
    _ => name,
  };

  bool get isRunning => activeState.isRunning;

  bool get isFailed => activeState.isFailed;

  bool get isInactive => activeState.isInactive;
}

@freezed
class UnitFileInfo with _$UnitFileInfo {
  const factory UnitFileInfo({
    required String path,

    required String name,

    required UnitFileState state,
  }) = _UnitFileInfo;

  const UnitFileInfo._();

  factory UnitFileInfo.fromJson(Map<String, dynamic> json) =>
      _$UnitFileInfoFromJson(json);

  UnitType? get type => UnitType.fromUnitName(name);

  bool get canBeEnabled => state.canBeEnabled;

  bool get isEnabled => state.isEnabled;
}
