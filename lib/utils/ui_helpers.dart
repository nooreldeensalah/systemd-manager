import 'package:flutter/material.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:yaru/yaru.dart';

/// Shared UI helper functions to avoid duplication across widgets.

/// Returns the appropriate color for a journal priority level.
Color getPriorityColor(JournalPriority priority) => switch (priority) {
      JournalPriority.emergency ||
      JournalPriority.alert ||
      JournalPriority.critical =>
        Colors.red.shade700,
      JournalPriority.error => Colors.red,
      JournalPriority.warning => Colors.orange,
      JournalPriority.notice => Colors.blue,
      JournalPriority.info => Colors.green,
      JournalPriority.debug => Colors.grey,
    };

/// Returns the appropriate icon for a unit type.
IconData getUnitTypeIcon(UnitType? type) => switch (type) {
      UnitType.service => YaruIcons.settings,
      UnitType.socket => YaruIcons.network,
      UnitType.target => YaruIcons.ubuntu_logo_simple,
      UnitType.device => YaruIcons.drive_harddisk,
      UnitType.mount => YaruIcons.drive_harddisk_filled,
      UnitType.automount => YaruIcons.drive_harddisk,
      UnitType.swap => YaruIcons.chip,
      UnitType.timer => YaruIcons.clock,
      UnitType.path => YaruIcons.folder,
      UnitType.slice => YaruIcons.app_grid,
      UnitType.scope => YaruIcons.window,
      null => YaruIcons.document,
    };

/// Returns the color for a unit type icon based on theme brightness.
Color getUnitTypeIconColor(UnitType? type, ThemeData theme) {
  final isDark = theme.brightness == Brightness.dark;
  return switch (type) {
    UnitType.service => isDark ? Colors.blue.shade300 : Colors.blue.shade600,
    UnitType.socket => isDark ? Colors.purple.shade300 : Colors.purple.shade600,
    UnitType.target => isDark ? Colors.green.shade300 : Colors.green.shade600,
    UnitType.timer => isDark ? Colors.orange.shade300 : Colors.orange.shade600,
    UnitType.mount ||
    UnitType.automount =>
      isDark ? Colors.brown.shade300 : Colors.brown.shade600,
    UnitType.device => isDark ? Colors.teal.shade300 : Colors.teal.shade600,
    UnitType.swap => isDark ? Colors.cyan.shade300 : Colors.cyan.shade600,
    UnitType.path => isDark ? Colors.amber.shade300 : Colors.amber.shade600,
    UnitType.slice ||
    UnitType.scope =>
      isDark ? Colors.indigo.shade300 : Colors.indigo.shade600,
    null => isDark ? Colors.grey.shade400 : Colors.grey.shade600,
  };
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
