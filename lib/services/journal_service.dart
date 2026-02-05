import 'dart:io';

import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/services/parsers/journal_parser.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

final _log = Logger('JournalService');

class JournalService {
  JournalService({this.parser = const JournalParser()});

  final JournalParser parser;

  Future<List<JournalEntry>> query(JournalFilter filter) async {
    final args = filter.toArguments();

    _log.debug('Running journalctl with args: $args');

    final result = await Process.run('journalctl', args);

    if (result.exitCode != 0) {
      final stderr = result.stderr as String;
      _log.error('journalctl failed: $stderr');
      throw Exception('journalctl failed: $stderr');
    }

    return parser.parseJournalEntries(result.stdout as String);
  }

  Future<List<JournalEntry>> queryUnit(
    String unitName, {
    int limit = 100,
    JournalPriority minPriority = JournalPriority.debug,
  }) async {
    return query(
      JournalFilter(unitName: unitName, limit: limit, minPriority: minPriority),
    );
  }

  Future<List<BootRecord>> listBoots() async {
    // Try JSON format first
    final result = await Process.run('journalctl', [
      '--list-boots',
      '-o',
      'json',
    ]);

    if (result.exitCode != 0) {
      // Fallback to text format if JSON fails (older systemd versions)
      final textResult = await Process.run('journalctl', ['--list-boots']);
      if (textResult.exitCode != 0) {
        throw Exception('Failed to list boots: ${textResult.stderr}');
      }
      return parser.parseBootRecords(
        textResult.stdout as String,
        isJson: false,
      );
    }

    return parser.parseBootRecords(result.stdout as String);
  }

  Future<JournalDiskUsage> getDiskUsage() async {
    final result = await Process.run('journalctl', ['--disk-usage']);

    if (result.exitCode != 0) {
      throw Exception('Failed to get disk usage: ${result.stderr}');
    }

    return parser.parseDiskUsage(result.stdout as String);
  }
}
