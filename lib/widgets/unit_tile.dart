import 'package:flutter/material.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/utils/ui_helpers.dart';
import 'package:systemd_manager/widgets/status_badge.dart';
import 'package:yaru/yaru.dart';

class UnitTile extends StatelessWidget {
  const UnitTile({
    required this.unit,
    super.key,
    this.onTap,
    this.onStart,
    this.onStop,
    this.onRestart,
    this.trailing,
    this.selected = false,
    this.dense = false,
  });

  final UnitInfo unit;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;
  final Widget? trailing;
  final bool selected;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      selected: selected,
      dense: dense,
      onTap: onTap,
      leading: _UnitTypeIcon(type: unit.type),
      title: Text(
        unit.name,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        unit.description,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
      trailing: trailing ?? _buildTrailing(context),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusBadge.fromUnitInfo(unit, size: StatusBadgeSize.small),
        if (onStart != null || onStop != null || onRestart != null) ...[
          const SizedBox(width: 8),
          _UnitActions(
            isRunning: unit.isRunning,
            onStart: onStart,
            onStop: onStop,
            onRestart: onRestart,
          ),
        ],
      ],
    );
  }
}

class _UnitTypeIcon extends StatelessWidget {
  const _UnitTypeIcon({required this.type});

  final UnitType? type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        getUnitTypeIcon(type),
        size: 20,
        color: getUnitTypeIconColor(type, theme),
      ),
    );
  }
}

class _UnitActions extends StatelessWidget {
  const _UnitActions({
    required this.isRunning,
    this.onStart,
    this.onStop,
    this.onRestart,
  });

  final bool isRunning;
  final VoidCallback? onStart;
  final VoidCallback? onStop;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isRunning && onStart != null)
          IconButton(
            icon: const Icon(YaruIcons.media_play),
            iconSize: 18,
            onPressed: onStart,
            tooltip: 'Start',
            visualDensity: VisualDensity.compact,
          ),
        if (isRunning && onStop != null)
          IconButton(
            icon: const Icon(YaruIcons.media_stop),
            iconSize: 18,
            onPressed: onStop,
            tooltip: 'Stop',
            visualDensity: VisualDensity.compact,
          ),
        if (onRestart != null)
          IconButton(
            icon: const Icon(YaruIcons.refresh),
            iconSize: 18,
            onPressed: onRestart,
            tooltip: 'Restart',
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
