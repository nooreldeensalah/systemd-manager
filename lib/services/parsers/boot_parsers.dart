import 'package:systemd_manager/models/boot_timings.dart';

/// Parses systemd-analyze output into structured data.
///
/// This isolates the parsing logic from the model classes, keeping models
/// as pure data containers and following single responsibility principle.
class BootTimingsParser {
  const BootTimingsParser();

  /// Parses output from `systemd-analyze time`, `blame`, and `critical-chain`.
  BootTimings parse({
    required String timeOutput,
    required String blameOutput,
    required String criticalChainOutput,
  }) {
    return BootTimings(
      totalTime: _parseTotalTime(timeOutput),
      firmwareTime: _parseComponent(timeOutput, 'firmware'),
      loaderTime: _parseComponent(timeOutput, 'loader'),
      kernelTime: _parseComponent(timeOutput, 'kernel') ?? Duration.zero,
      initrdTime: _parseComponent(timeOutput, 'initrd'),
      userspaceTime: _parseComponent(timeOutput, 'userspace') ?? Duration.zero,
      graphicalTargetTime: _parseGraphicalTarget(timeOutput),
      blame: _parseBlame(blameOutput),
      criticalChain: _parseCriticalChain(criticalChainOutput),
    );
  }

  Duration? _parseComponent(String output, String component) {
    final regex = RegExp(r'(?:(\d+)min\s+)?([\d.]+)s\s*\(' + component + r'\)');
    final match = regex.firstMatch(output);
    if (match != null) {
      final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      final seconds = double.tryParse(match.group(2) ?? '0') ?? 0;
      return Duration(
        milliseconds: (minutes * 60 * 1000 + seconds * 1000).round(),
      );
    }
    return null;
  }

  Duration _parseTotalTime(String output) {
    // Try to match "= X.XXXs" or "= Xmin X.XXXs" format
    final totalRegex = RegExp(r'=\s*(?:(\d+)min\s+)?([\d.]+)s');
    final match = totalRegex.firstMatch(output);
    if (match != null) {
      final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      final seconds = double.tryParse(match.group(2) ?? '0') ?? 0;
      return Duration(
        milliseconds: (minutes * 60 * 1000 + seconds * 1000).round(),
      );
    }

    // Fallback: sum all components
    final components = ['firmware', 'loader', 'kernel', 'initrd', 'userspace'];
    var totalMs = 0;
    for (final comp in components) {
      final duration = _parseComponent(output, comp);
      if (duration != null) {
        totalMs += duration.inMilliseconds;
      }
    }
    return Duration(milliseconds: totalMs);
  }

  Duration? _parseGraphicalTarget(String output) {
    // "graphical.target reached after X.XXXs in userspace"
    final regex = RegExp(r'graphical\.target reached after ([\d.]+)s');
    final match = regex.firstMatch(output);
    if (match != null) {
      final seconds = double.tryParse(match.group(1) ?? '0') ?? 0;
      return Duration(milliseconds: (seconds * 1000).round());
    }
    return null;
  }

  List<BlameEntry> _parseBlame(String output) {
    final entries = <BlameEntry>[];
    // Matches: "  1.234s unit-name.service" or "  1min 2.345s unit-name.service"
    final regex = RegExp(
      r'^\s*(?:(\d+)min\s+)?([\d.]+)(ms|s)\s+(\S+)\s*$',
      multiLine: true,
    );

    for (final match in regex.allMatches(output)) {
      final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      final value = double.tryParse(match.group(2) ?? '0') ?? 0;
      final unit = match.group(3) ?? 's';
      final unitName = match.group(4) ?? '';

      if (unitName.isEmpty) continue;

      int milliseconds;
      if (unit == 'ms') {
        milliseconds = value.round();
      } else {
        milliseconds = (minutes * 60 * 1000 + value * 1000).round();
      }

      entries.add(
        BlameEntry(
          unitName: unitName,
          time: Duration(milliseconds: milliseconds),
        ),
      );
    }
    return entries;
  }

  List<CriticalChainUnit> _parseCriticalChain(String output) {
    final units = <CriticalChainUnit>[];
    // Matches: "unit.service @1.234s +0.456s" or "unit.target @1.234s"
    final regex = RegExp(
      r'([a-zA-Z][\w\-@.]+\.(?:service|target|socket|timer|mount|device))\s+@([\d.]+)s(?:\s+\+([\d.]+)s)?',
    );

    for (final match in regex.allMatches(output)) {
      final unitName = match.group(1) ?? '';
      final activatedAt = double.tryParse(match.group(2) ?? '0') ?? 0;
      final timeToActivate = double.tryParse(match.group(3) ?? '0') ?? 0;

      if (unitName.isNotEmpty) {
        units.add(
          CriticalChainUnit(
            unitName: unitName,
            activatedAt: Duration(milliseconds: (activatedAt * 1000).round()),
            timeToActivate: Duration(
              milliseconds: (timeToActivate * 1000).round(),
            ),
          ),
        );
      }
    }
    return units;
  }
}
