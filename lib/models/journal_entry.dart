import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:systemd_manager/utils/formatters.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

enum JournalPriority {
  emergency(0, 'Emergency'),
  alert(1, 'Alert'),
  critical(2, 'Critical'),
  error(3, 'Error'),
  warning(4, 'Warning'),
  notice(5, 'Notice'),
  info(6, 'Info'),
  debug(7, 'Debug');

  const JournalPriority(this.value, this.displayName);

  final int value;
  final String displayName;

  static JournalPriority fromValue(int value) {
    return JournalPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => JournalPriority.info,
    );
  }

  bool get isError => value <= 3;

  bool get isWarning => value == 4;
}

@freezed
class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required DateTime timestamp,

    required String message,

    required JournalPriority priority,

    String? unitName,

    String? syslogIdentifier,

    int? pid,

    int? uid,

    int? gid,

    String? hostname,

    String? bootId,

    String? machineId,

    String? transport,

    String? cursor,

    int? monotonicTimestamp,

    String? cmdLine,

    String? exe,

    @Default({}) Map<String, String> extraFields,
  }) = _JournalEntry;

  const JournalEntry._();

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);

  factory JournalEntry.fromJournalctlJson(Map<String, dynamic> json) {
    final timestampMicros =
        int.tryParse(json['__REALTIME_TIMESTAMP']?.toString() ?? '0') ?? 0;
    final timestamp = DateTime.fromMicrosecondsSinceEpoch(
      timestampMicros,
      isUtc: true,
    ).toLocal();

    final priorityValue =
        int.tryParse(json['PRIORITY']?.toString() ?? '6') ?? 6;

    return JournalEntry(
      timestamp: timestamp,
      message: json['MESSAGE']?.toString() ?? '',
      priority: JournalPriority.fromValue(priorityValue),
      unitName: json['_SYSTEMD_UNIT']?.toString(),
      syslogIdentifier: json['SYSLOG_IDENTIFIER']?.toString(),
      pid: int.tryParse(json['_PID']?.toString() ?? ''),
      uid: int.tryParse(json['_UID']?.toString() ?? ''),
      gid: int.tryParse(json['_GID']?.toString() ?? ''),
      hostname: json['_HOSTNAME']?.toString(),
      bootId: json['_BOOT_ID']?.toString(),
      machineId: json['_MACHINE_ID']?.toString(),
      transport: json['_TRANSPORT']?.toString(),
      cursor: json['__CURSOR']?.toString(),
      monotonicTimestamp: int.tryParse(
        json['__MONOTONIC_TIMESTAMP']?.toString() ?? '',
      ),
      cmdLine: json['_CMDLINE']?.toString(),
      exe: json['_EXE']?.toString(),
    );
  }

  String get timestampDisplay {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  String get fullTimestampDisplay {
    return '${timestamp.year}-'
        '${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')} '
        '$timestampDisplay';
  }

  String get source => unitName ?? syslogIdentifier ?? 'unknown';
}

@freezed
class JournalFilter with _$JournalFilter {
  const factory JournalFilter({
    String? unitName,

    @Default(JournalPriority.debug) JournalPriority minPriority,

    DateTime? since,

    DateTime? until,

    String? bootId,

    String? searchText,

    @Default(25) int limit,

    @Default(false) bool follow,

    @Default(true) bool showKernel,

    String? cursor,

    @Default(true) bool reverse,
  }) = _JournalFilter;

  const JournalFilter._();

  factory JournalFilter.fromJson(Map<String, dynamic> json) =>
      _$JournalFilterFromJson(json);

  List<String> toArguments() {
    final args = <String>['-o', 'json'];

    if (unitName != null && unitName!.isNotEmpty) {
      args.addAll(['-u', unitName!]);
    }

    args.addAll(['-p', minPriority.value.toString()]);

    if (since != null) {
      args.addAll(['--since', since!.toIso8601String()]);
    }

    if (until != null) {
      args.addAll(['--until', until!.toIso8601String()]);
    }

    if (bootId != null && bootId!.isNotEmpty) {
      args.addAll(['-b', bootId!]);
    } else {
      args.add('-b');
    }

    if (searchText != null && searchText!.isNotEmpty) {
      args.addAll(['-g', searchText!]);
    }

    args.addAll(['-n', limit.toString()]);

    if (reverse) {
      args.add('-r');
    }

    if (cursor != null && cursor!.isNotEmpty) {
      // Note: systemd might use --after-cursor or --cursor depending on version/intent.
      // usually --after-cursor is for "give me next page".
      args.addAll(['--after-cursor', cursor!]);
    }

    if (follow) {
      args.add('-f');
    }

    if (!showKernel) {
      args.add('--no-kernel');
    }

    return args;
  }
}

/// Disk usage statistics for systemd journal.
@freezed
class JournalDiskUsage with _$JournalDiskUsage {
  const factory JournalDiskUsage({
    required int bytes,
    required String displayString,
  }) = _JournalDiskUsage;

  const JournalDiskUsage._();

  factory JournalDiskUsage.fromJson(Map<String, dynamic> json) =>
      _$JournalDiskUsageFromJson(json);

  String get humanReadable => formatBytes(bytes);
}
