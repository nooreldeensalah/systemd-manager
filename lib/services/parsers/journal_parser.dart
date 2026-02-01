import 'dart:convert';
import 'package:systemd_manager/models/models.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

final _log = Logger('JournalParser');

class JournalParser {
  const JournalParser();

  List<JournalEntry> parseJournalEntries(String stdout) {
    final entries = <JournalEntry>[];

    for (final line in stdout.split('\n')) {
      if (line.isEmpty) continue;

      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        entries.add(JournalEntry.fromJournalctlJson(json));
      } on FormatException catch (e) {
        _log.warning('Failed to parse journal line: $e');
      }
    }
    return entries;
  }

  List<BootRecord> parseBootRecords(String stdout, {bool isJson = true}) {
    if (isJson) {
      return _parseBootRecordsJson(stdout);
    } else {
      return _parseBootRecordsText(stdout);
    }
  }

  List<BootRecord> _parseBootRecordsText(String stdout) {
    final boots = <BootRecord>[];
    final lines = stdout.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final index = int.tryParse(parts[0]) ?? 0;
          final bootId = parts[1];
          boots.add(
            BootRecord(
              index: index,
              bootId: bootId,
              firstEntry: DateTime.now(), // Simplified
              lastEntry: DateTime.now(),
            ),
          );
        }
      } on FormatException catch (e) {
        _log.warning('Failed to parse boot record: $e');
      }
    }
    return boots;
  }

  List<BootRecord> _parseBootRecordsJson(String stdout) {
    final boots = <BootRecord>[];
    try {
      final jsonList = jsonDecode(stdout) as List;
      for (final item in jsonList) {
        final index = item['index'];
        final bootId = item['boot_id']?.toString() ?? '';
        final firstEntry = item['first_entry'];
        final lastEntry = item['last_entry'];

        DateTime parseTimestamp(dynamic value) {
          if (value == null) return DateTime.now();
          if (value is int) {
            return DateTime.fromMicrosecondsSinceEpoch(value);
          }
          if (value is String) {
            return DateTime.tryParse(value) ?? DateTime.now();
          }
          return DateTime.now();
        }

        boots.add(
          BootRecord(
            index: index is int
                ? index
                : (int.tryParse(index?.toString() ?? '0') ?? 0),
            bootId: bootId,
            firstEntry: parseTimestamp(firstEntry),
            lastEntry: parseTimestamp(lastEntry),
          ),
        );
      }
    } on FormatException catch (e) {
      _log.warning('Failed to parse boots JSON: $e');
    }
    return boots;
  }

  JournalDiskUsage parseDiskUsage(String stdout) {
    final match = RegExp(r'([\d.]+)([KMGT]?)').firstMatch(stdout);

    if (match != null) {
      final value = double.tryParse(match.group(1) ?? '0') ?? 0;
      final unit = match.group(2) ?? '';

      int bytes;
      switch (unit) {
        case 'K':
          bytes = (value * 1024).round();
        case 'M':
          bytes = (value * 1024 * 1024).round();
        case 'G':
          bytes = (value * 1024 * 1024 * 1024).round();
        case 'T':
          bytes = (value * 1024 * 1024 * 1024 * 1024).round();
        default:
          bytes = value.round();
      }

      return JournalDiskUsage(bytes: bytes, displayString: stdout.trim());
    }

    return JournalDiskUsage(bytes: 0, displayString: stdout.trim());
  }
}
