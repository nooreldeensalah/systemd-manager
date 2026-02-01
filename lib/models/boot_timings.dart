import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:systemd_manager/utils/formatters.dart';

part 'boot_timings.freezed.dart';
part 'boot_timings.g.dart';

/// Boot timing metrics from systemd-analyze.
///
/// Contains the breakdown of boot time by phase (firmware, loader, kernel,
/// initrd, userspace) and lists of units contributing to boot time.
@freezed
class BootTimings with _$BootTimings {
  const factory BootTimings({
    required Duration totalTime,
    required Duration kernelTime,
    required Duration userspaceTime,
    Duration? firmwareTime,
    Duration? loaderTime,
    Duration? initrdTime,
    Duration? graphicalTargetTime,
    @Default([]) List<CriticalChainUnit> criticalChain,
    @Default([]) List<BlameEntry> blame,
  }) = _BootTimings;

  const BootTimings._();

  factory BootTimings.fromJson(Map<String, dynamic> json) =>
      _$BootTimingsFromJson(json);

  String get totalTimeDisplay => formatDuration(totalTime);
  String get kernelTimeDisplay => formatDuration(kernelTime);
  String get userspaceTimeDisplay => formatDuration(userspaceTime);
}

/// A unit that contributes to boot time.
@freezed
class BlameEntry with _$BlameEntry {
  const factory BlameEntry({required String unitName, required Duration time}) =
      _BlameEntry;

  const BlameEntry._();

  factory BlameEntry.fromJson(Map<String, dynamic> json) =>
      _$BlameEntryFromJson(json);

  String get timeDisplay => formatDuration(time);
}

/// A unit in the critical chain of the boot process.
@freezed
class CriticalChainUnit with _$CriticalChainUnit {
  const factory CriticalChainUnit({
    required String unitName,
    required Duration activatedAt,
    required Duration timeToActivate,
  }) = _CriticalChainUnit;

  const CriticalChainUnit._();

  factory CriticalChainUnit.fromJson(Map<String, dynamic> json) =>
      _$CriticalChainUnitFromJson(json);

  String get activatedAtDisplay => formatDurationSeconds(activatedAt);
  String get timeToActivateDisplay => formatDurationDelta(timeToActivate);
}

/// Record of a previous boot session from journalctl --list-boots.
@freezed
class BootRecord with _$BootRecord {
  const factory BootRecord({
    required int index,
    required String bootId,
    required DateTime firstEntry,
    required DateTime lastEntry,
  }) = _BootRecord;

  const BootRecord._();

  factory BootRecord.fromJson(Map<String, dynamic> json) =>
      _$BootRecordFromJson(json);

  String get displayName {
    if (index == 0) return 'Current boot';
    if (index == -1) return 'Previous boot';
    return 'Boot $index';
  }
}
