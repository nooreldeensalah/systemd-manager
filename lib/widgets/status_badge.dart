import 'package:flutter/material.dart';
import 'package:systemd_manager/models/models.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.activeState,
    super.key,
    this.showLabel = true,
    this.size = StatusBadgeSize.medium,
  });

  factory StatusBadge.fromUnitInfo(
    UnitInfo unit, {
    bool showLabel = true,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) {
    return StatusBadge(
      activeState: unit.activeState,
      showLabel: showLabel,
      size: size,
    );
  }

  factory StatusBadge.fromUnitStatus(
    UnitStatus status, {
    bool showLabel = true,
    StatusBadgeSize size = StatusBadgeSize.medium,
  }) {
    return StatusBadge(
      activeState: status.activeState,
      showLabel: showLabel,
      size: size,
    );
  }

  final UnitActiveState activeState;
  final bool showLabel;
  final StatusBadgeSize size;

  _StatusStyle _getStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return switch (activeState) {
      UnitActiveState.active || UnitActiveState.reloading => _StatusStyle(
          label: activeState == UnitActiveState.reloading
              ? 'Reloading'
              : 'Active',
          color: Colors.green,
          isDark: isDark,
        ),
      UnitActiveState.failed =>
        _StatusStyle(label: 'Failed', color: Colors.red, isDark: isDark),
      UnitActiveState.activating || UnitActiveState.deactivating => _StatusStyle(
          label: activeState == UnitActiveState.activating
              ? 'Activating'
              : 'Stopping',
          color: Colors.orange,
          isDark: isDark,
        ),
      UnitActiveState.inactive || UnitActiveState.maintenance => _StatusStyle(
          label: activeState == UnitActiveState.maintenance
              ? 'Maintenance'
              : 'Inactive',
          color: Colors.grey,
          isDark: isDark,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = _getStyle(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: size.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(size.borderRadius),
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size.indicatorSize,
            height: size.indicatorSize,
            decoration: BoxDecoration(
              color: style.indicator,
              shape: BoxShape.circle,
            ),
          ),
          if (showLabel) ...[
            SizedBox(width: size.spacing),
            Text(
              style.label,
              style: TextStyle(
                fontSize: size.fontSize,
                fontWeight: FontWeight.w500,
                color: style.text,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EnableBadge extends StatelessWidget {
  const EnableBadge({
    required this.state,
    super.key,
    this.showLabel = true,
    this.size = StatusBadgeSize.medium,
  });

  final UnitFileState? state;
  final bool showLabel;
  final StatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    if (state == null) {
      return const SizedBox.shrink();
    }

    final style = _getStyle(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: size.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(size.borderRadius),
        border: Border.all(color: style.border),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: size.fontSize,
          fontWeight: FontWeight.w500,
          color: style.text,
        ),
      ),
    );
  }

  _StatusStyle _getStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (state == null) {
      return _StatusStyle(
        label: '',
        color: Colors.transparent,
        isDark: isDark,
        isTransparent: true,
        textColor: theme.textTheme.bodySmall?.color ?? Colors.grey,
      );
    }

    if (state!.isEnabled) {
      return _StatusStyle(label: 'Enabled', color: Colors.blue, isDark: isDark);
    }

    if (state == UnitFileState.masked || state == UnitFileState.maskedRuntime) {
      return _StatusStyle(
        label: 'Masked',
        color: Colors.purple,
        isDark: isDark,
      );
    }

    return _StatusStyle(
      label: _getLabelForState(state!),
      color: Colors.grey,
      isDark: isDark,
    );
  }

  String _getLabelForState(UnitFileState state) => switch (state) {
        UnitFileState.enabled || UnitFileState.enabledRuntime => 'Enabled',
        UnitFileState.disabled => 'Disabled',
        UnitFileState.static_ => 'Static',
        UnitFileState.masked || UnitFileState.maskedRuntime => 'Masked',
        UnitFileState.linked || UnitFileState.linkedRuntime => 'Linked',
        UnitFileState.alias => 'Alias',
        UnitFileState.indirect => 'Indirect',
        UnitFileState.generated => 'Generated',
        UnitFileState.transient => 'Transient',
        UnitFileState.bad => 'Bad',
      };
}

class _StatusStyle {
  factory _StatusStyle({
    required String label,
    required Color color,
    required bool isDark,
    bool isTransparent = false,
    Color? textColor,
  }) {
    Color background;
    Color border;
    Color indicator;
    Color text;

    if (isTransparent) {
      background = Colors.transparent;
      border = Colors.transparent;
      indicator = Colors.transparent;
      text = textColor ?? Colors.grey;
    } else {
      background = isDark
          ? color.withValues(alpha: 0.3)
          : (color is MaterialColor
                ? color.shade50
                : color.withValues(alpha: 0.1));

      if (color is MaterialColor) {
        final mc = color;
        border = isDark ? mc.shade700 : mc.shade200;
        text = isDark ? mc.shade300 : mc.shade700;
        indicator = color;
      } else {
        border = color.withValues(alpha: isDark ? 0.7 : 0.3);
        text = color;
        indicator = color;
      }
    }

    return _StatusStyle._(
      label: label,
      background: background,
      border: border,
      indicator: indicator,
      text: text,
    );
  }

  const _StatusStyle._({
    required this.label,
    required this.background,
    required this.border,
    required this.indicator,
    required this.text,
  });

  final String label;
  final Color background;
  final Color border;
  final Color indicator;
  final Color text;
}

enum StatusBadgeSize {
  small(
    horizontalPadding: 6,
    verticalPadding: 2,
    indicatorSize: 6,
    spacing: 4,
    fontSize: 10,
    borderRadius: 4,
  ),
  medium(
    horizontalPadding: 8,
    verticalPadding: 4,
    indicatorSize: 8,
    spacing: 6,
    fontSize: 12,
    borderRadius: 6,
  ),
  large(
    horizontalPadding: 12,
    verticalPadding: 6,
    indicatorSize: 10,
    spacing: 8,
    fontSize: 14,
    borderRadius: 8,
  );

  const StatusBadgeSize({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.indicatorSize,
    required this.spacing,
    required this.fontSize,
    required this.borderRadius,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double indicatorSize;
  final double spacing;
  final double fontSize;
  final double borderRadius;
}
