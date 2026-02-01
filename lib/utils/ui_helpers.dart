import 'package:flutter/material.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:yaru/yaru.dart';

/// Shared UI helper functions to avoid duplication across widgets.

/// Returns the appropriate color for a journal priority level.
Color getPriorityColor(JournalPriority priority) {
  switch (priority) {
    case JournalPriority.emergency:
    case JournalPriority.alert:
    case JournalPriority.critical:
      return Colors.red.shade700;
    case JournalPriority.error:
      return Colors.red;
    case JournalPriority.warning:
      return Colors.orange;
    case JournalPriority.notice:
      return Colors.blue;
    case JournalPriority.info:
      return Colors.green;
    case JournalPriority.debug:
      return Colors.grey;
  }
}

/// Returns the appropriate icon for a unit type.
IconData getUnitTypeIcon(UnitType? type) {
  switch (type) {
    case UnitType.service:
      return YaruIcons.settings;
    case UnitType.socket:
      return YaruIcons.network;
    case UnitType.target:
      return YaruIcons.ubuntu_logo_simple;
    case UnitType.device:
      return YaruIcons.drive_harddisk;
    case UnitType.mount:
      return YaruIcons.drive_harddisk_filled;
    case UnitType.automount:
      return YaruIcons.drive_harddisk;
    case UnitType.swap:
      return YaruIcons.chip;
    case UnitType.timer:
      return YaruIcons.clock;
    case UnitType.path:
      return YaruIcons.folder;
    case UnitType.slice:
      return YaruIcons.app_grid;
    case UnitType.scope:
      return YaruIcons.window;
    case null:
      return YaruIcons.document;
  }
}

/// Returns the color for a unit type icon based on theme brightness.
Color getUnitTypeIconColor(UnitType? type, ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  switch (type) {
    case UnitType.service:
      return isDark ? Colors.blue.shade300 : Colors.blue.shade600;
    case UnitType.socket:
      return isDark ? Colors.purple.shade300 : Colors.purple.shade600;
    case UnitType.target:
      return isDark ? Colors.green.shade300 : Colors.green.shade600;
    case UnitType.timer:
      return isDark ? Colors.orange.shade300 : Colors.orange.shade600;
    case UnitType.mount:
    case UnitType.automount:
      return isDark ? Colors.brown.shade300 : Colors.brown.shade600;
    case UnitType.device:
      return isDark ? Colors.teal.shade300 : Colors.teal.shade600;
    case UnitType.swap:
      return isDark ? Colors.cyan.shade300 : Colors.cyan.shade600;
    case UnitType.path:
      return isDark ? Colors.amber.shade300 : Colors.amber.shade600;
    case UnitType.slice:
    case UnitType.scope:
      return isDark ? Colors.indigo.shade300 : Colors.indigo.shade600;
    case null:
      return isDark ? Colors.grey.shade400 : Colors.grey.shade600;
  }
}

/// Formats a timestamp for display with relative time suffix.
String formatTimestampWithRelative(DateTime timestamp) {
  final now = DateTime.now();
  final diff = now.difference(timestamp);

  final date =
      '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  final time =
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

  if (diff.inDays > 0) {
    return '$date $time (${diff.inDays}d ago)';
  } else if (diff.inHours > 0) {
    return '$time (${diff.inHours}h ago)';
  } else if (diff.inMinutes > 0) {
    return '$time (${diff.inMinutes}m ago)';
  }
  return '$time (just now)';
}

/// Formats a timestamp for compact log display.
String formatTimestampCompact(DateTime timestamp) {
  return '${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}
