import 'dart:io';

import 'package:systemd_manager/models/boot_timings.dart';
import 'package:systemd_manager/services/parsers/parsers.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

final _log = Logger('AnalyzeService');

class AnalyzeService {
  AnalyzeService();

  final _bootParser = const BootTimingsParser();

  Future<BootTimings> getBootTimings() async {
    final timeOutput = await _runAnalyze(['time']);
    final blameOutput = await _runAnalyze(['blame']);
    final criticalChainOutput = await _runAnalyze(['critical-chain']);

    return _bootParser.parse(
      timeOutput: timeOutput,
      blameOutput: blameOutput,
      criticalChainOutput: criticalChainOutput,
    );
  }

  Future<String> _runAnalyze(List<String> args) async {
    _log.debug('Running systemd-analyze with args: $args');

    final result = await Process.run('systemd-analyze', args);

    if (result.exitCode != 0) {
      final stderr = result.stderr as String;
      _log.error('systemd-analyze failed: $stderr');
      throw Exception('systemd-analyze failed: $stderr');
    }

    return result.stdout as String;
  }
}
