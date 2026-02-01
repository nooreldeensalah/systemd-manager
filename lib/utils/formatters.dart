// Pure Dart formatters for Duration, bytes, and other data types.
// These are used by both models and UI layers.

/// Formats a duration for human-readable display.
///
/// Examples:
/// - 3min 45s
/// - 1.234s
/// - 456ms
String formatDuration(Duration duration) {
  if (duration.inMinutes > 0) {
    final seconds = duration.inSeconds.remainder(60);
    return '${duration.inMinutes}min ${seconds}s';
  }
  if (duration.inMilliseconds >= 1000) {
    final seconds = duration.inMilliseconds / 1000;
    return '${seconds.toStringAsFixed(3)}s';
  }
  return '${duration.inMilliseconds}ms';
}

/// Formats a duration with "+" prefix for deltas.
///
/// Examples:
/// - +1.234s
/// - +456ms
/// - "-" for zero duration
String formatDurationDelta(Duration duration) {
  if (duration.inMilliseconds == 0) return '-';
  if (duration.inMilliseconds < 1000) {
    return '+${duration.inMilliseconds}ms';
  }
  final seconds = duration.inMilliseconds / 1000;
  return '+${seconds.toStringAsFixed(3)}s';
}

/// Formats a duration as seconds with 3 decimal places.
///
/// Example: "1.234s"
String formatDurationSeconds(Duration duration) {
  final seconds = duration.inMilliseconds / 1000;
  return '${seconds.toStringAsFixed(3)}s';
}

/// Formats bytes into human-readable format (B, K, M, G).
///
/// Examples:
/// - 512B
/// - 1.5K
/// - 256.3M
/// - 2.1G
String formatBytes(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}K';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}M';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}G';
}

/// Formats an uptime duration into a human-readable display.
///
/// Examples:
/// - "5d 12h" for multi-day durations
/// - "3h 45m" for multi-hour durations
/// - "12m 30s" for multi-minute durations
/// - "45s" for seconds-only durations
/// - "-" for null duration
String formatUptime(Duration? duration) {
  if (duration == null) return '-';

  if (duration.inDays > 0) {
    return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
  }
  if (duration.inHours > 0) {
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }
  if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
  }
  return '${duration.inSeconds}s';
}
