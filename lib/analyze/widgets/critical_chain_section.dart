import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/models/boot_timings.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/widgets/widgets.dart';
import 'package:yaru/yaru.dart';

class CriticalChainSection extends ConsumerWidget {
  const CriticalChainSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timingsAsync = ref.watch(bootTimingsProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(YaruIcons.network, size: 20),
                const SizedBox(width: 8),
                Text('Critical Chain', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Units that blocked boot, in dependency order',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            _buildLegend(context),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            timingsAsync.when(
              data: (timings) {
                if (timings.criticalChain.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No critical chain data available'),
                    ),
                  );
                }

                return _CriticalChainTree(units: timings.criticalChain);
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: LoadingView(),
              ),
              error: (error, _) => ErrorView(
                message: 'Error',
                details: error.toString(),
                onRetry: () => ref.invalidate(bootTimingsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text('Started at (since boot)', style: labelStyle),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(width: 4),
            Text('Time this unit took', style: labelStyle),
          ],
        ),
      ],
    );
  }
}

/// Tree view widget that properly handles expand/collapse.
class _CriticalChainTree extends StatefulWidget {
  const _CriticalChainTree({required this.units});

  final List<CriticalChainUnit> units;

  @override
  State<_CriticalChainTree> createState() => _CriticalChainTreeState();
}

class _CriticalChainTreeState extends State<_CriticalChainTree> {
  // Track which indices are collapsed (hidden)
  final Set<int> _collapsedParents = {};

  @override
  Widget build(BuildContext context) {
    final visibleUnits = <_TreeNode>[];

    // Build tree nodes with visibility
    for (var i = 0; i < widget.units.length; i++) {
      final unit = widget.units[i];
      final hasChildren = i < widget.units.length - 1;
      final isLastChild = i == widget.units.length - 1;

      // Check if this node should be hidden (any ancestor is collapsed)
      var isHidden = false;
      for (final collapsedIdx in _collapsedParents) {
        if (i > collapsedIdx) {
          isHidden = true;
          break;
        }
      }

      if (!isHidden) {
        visibleUnits.add(
          _TreeNode(
            index: i,
            unit: unit,
            depth: i,
            hasChildren: hasChildren,
            isExpanded: !_collapsedParents.contains(i),
            isLastChild: isLastChild,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visibleUnits.map((node) {
        return _CriticalChainRow(
          node: node,
          onToggle: node.hasChildren
              ? () {
                  setState(() {
                    if (_collapsedParents.contains(node.index)) {
                      _collapsedParents.remove(node.index);
                    } else {
                      _collapsedParents.add(node.index);
                    }
                  });
                }
              : null,
        );
      }).toList(),
    );
  }
}

class _TreeNode {
  const _TreeNode({
    required this.index,
    required this.unit,
    required this.depth,
    required this.hasChildren,
    required this.isExpanded,
    required this.isLastChild,
  });

  final int index;
  final CriticalChainUnit unit;
  final int depth;
  final bool hasChildren;
  final bool isExpanded;
  final bool isLastChild;
}

class _CriticalChainRow extends StatelessWidget {
  const _CriticalChainRow({required this.node, this.onToggle});

  final _TreeNode node;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = node.unit;
    final tookTime = unit.timeToActivate.inMilliseconds;
    final isSlow = tookTime > 500;
    final isVerySlow = tookTime > 2000;

    return Padding(
      padding: EdgeInsets.only(left: node.depth * 16.0),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: isVerySlow
                ? Colors.red.withValues(alpha: 0.08)
                : isSlow
                ? Colors.orange.withValues(alpha: 0.06)
                : null,
          ),
          child: Row(
            children: [
              // Expand/collapse toggle
              SizedBox(
                width: 20,
                height: 20,
                child: node.hasChildren
                    ? Icon(
                        node.isExpanded
                            ? YaruIcons.pan_down
                            : YaruIcons.pan_end,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 4),

              // "Started at" badge
              Tooltip(
                message:
                    'This unit was ready ${unit.activatedAtDisplay} after boot started',
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    unit.activatedAtDisplay,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),

              // "Took" badge (only if > 0)
              if (tookTime > 0) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message:
                      'This unit took ${unit.timeToActivateDisplay} to start',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _getTookTimeColor(
                        tookTime,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getTookTimeColor(
                          tookTime,
                        ).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      unit.timeToActivateDisplay,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getTookTimeColor(tookTime),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(width: 12),

              // Unit name
              Expanded(
                child: Text(
                  unit.unitName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isVerySlow ? FontWeight.bold : null,
                    color: isSlow ? null : theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTookTimeColor(int milliseconds) {
    if (milliseconds >= 10000) return Colors.red.shade800;
    if (milliseconds > 2000) return Colors.red;
    if (milliseconds > 1000) return Colors.orange.shade700;
    if (milliseconds > 500) return Colors.amber.shade800;
    return Colors.green;
  }
}
