import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:yaru/yaru.dart';

class JournalHeader extends ConsumerStatefulWidget {
  const JournalHeader({
    required this.searchController,
    required this.onSearch,
    super.key,
  });

  final TextEditingController searchController;
  final VoidCallback onSearch;

  @override
  ConsumerState<JournalHeader> createState() => _JournalHeaderState();
}

class _JournalHeaderState extends ConsumerState<JournalHeader> {
  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(journalFilterNotifierProvider);
    final diskUsageAsync = ref.watch(journalDiskUsageProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Journal', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(width: 16),
              diskUsageAsync.when(
                data: (usage) => Text(
                  'Disk usage: ${usage.humanReadable}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Spacer(),
              YaruIconButton(
                icon: const Icon(YaruIcons.refresh),
                onPressed: () =>
                    ref.read(journalControllerProvider.notifier).refresh(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 300,
                height: 40,
                child: TextField(
                  controller: widget.searchController,
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: const Icon(YaruIcons.search, size: 18),
                    suffixIcon: widget.searchController.text.isNotEmpty
                        ? YaruIconButton(
                            icon: const Icon(YaruIcons.edit_clear, size: 18),
                            onPressed: () {
                              widget.searchController.clear();
                              widget.onSearch();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => widget.onSearch(),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 150,
                child: YaruPopupMenuButton<JournalPriority>(
                  initialValue: filter.minPriority,
                  tooltip: 'Filter by priority',
                  onSelected: (priority) {
                    ref
                        .read(journalFilterNotifierProvider.notifier)
                        .setMinPriority(priority);
                  },
                  child: Text(
                    filter.minPriority.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  itemBuilder: (context) {
                    return JournalPriority.values.map((priority) {
                      return PopupMenuItem(
                        value: priority,
                        child: Text(priority.displayName),
                      );
                    }).toList();
                  },
                ),
              ),
              const SizedBox(width: 16),
              const _BootSelector(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _UnitNameAutocomplete(currentUnitName: filter.unitName),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(YaruIcons.edit_clear, size: 18),
                label: const Text('Clear filters'),
                onPressed: () {
                  widget.searchController.clear();
                  ref
                      .read(journalFilterNotifierProvider.notifier)
                      .clearFilters();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitNameAutocomplete extends ConsumerWidget {
  const _UnitNameAutocomplete({required this.currentUnitName});

  final String? currentUnitName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitNamesAsync = ref.watch(journalUnitNamesProvider);

    return unitNamesAsync.when(
      data: (unitNames) => SizedBox(
        width: 350,
        child: YaruAutocomplete<String>(
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return unitNames.take(20);
            }
            final query = textEditingValue.text.toLowerCase();
            return unitNames
                .where((name) => name.toLowerCase().contains(query))
                .take(20);
          },
          fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
            // Sync local controller with provider state
            if (currentUnitName != textController.text) {
              if (currentUnitName == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  textController.clear();
                });
              } else if (textController.text.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  textController.text = currentUnitName!;
                });
              }
            }

            return SizedBox(
              height: 40,
              child: TextField(
                controller: textController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Filter by unit name...',
                  prefixIcon: const Icon(YaruIcons.document, size: 18),
                  suffixIcon: textController.text.isNotEmpty
                      ? YaruIconButton(
                          icon: const Icon(YaruIcons.edit_clear, size: 18),
                          onPressed: () {
                            textController.clear();
                            ref
                                .read(journalFilterNotifierProvider.notifier)
                                .setUnitName(null);
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  ref
                      .read(journalFilterNotifierProvider.notifier)
                      .setUnitName(value.isEmpty ? null : value);
                },
              ),
            );
          },
          onSelected: (value) {
            ref.read(journalFilterNotifierProvider.notifier).setUnitName(value);
          },
          optionsMaxHeight: 300,
        ),
      ),
      loading: () => const SizedBox(
        width: 350,
        height: 40,
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Loading units...',
            prefixIcon: Icon(YaruIcons.document, size: 18),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ),
      error: (_, __) => SizedBox(
        width: 350,
        height: 40,
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Filter by unit name...',
            prefixIcon: Icon(YaruIcons.document, size: 18),
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) {
            ref
                .read(journalFilterNotifierProvider.notifier)
                .setUnitName(value.isEmpty ? null : value);
          },
        ),
      ),
    );
  }
}

class _BootSelector extends ConsumerWidget {
  const _BootSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootsAsync = ref.watch(availableBootsProvider);
    final filter = ref.watch(journalFilterNotifierProvider);

    return bootsAsync.when(
      data: (boots) {
        String getBootLabel(String? bootId) {
          if (bootId == null) return 'Current boot';
          if (bootId.isEmpty) return 'All boots';
          return boots
                  .where((b) => b.bootId == bootId)
                  .firstOrNull
                  ?.displayName ??
              'Unknown boot';
        }

        return SizedBox(
          width: 200,
          child: YaruPopupMenuButton<String?>(
            initialValue: filter.bootId,
            tooltip: 'Select boot',
            onSelected: (bootId) {
              ref
                  .read(journalFilterNotifierProvider.notifier)
                  .setBootId(bootId);
            },
            child: Text(
              getBootLabel(filter.bootId),
              overflow: TextOverflow.ellipsis,
            ),
            itemBuilder: (context) {
              return [
                const PopupMenuItem(child: Text('Current boot')),
                const PopupMenuItem(value: '', child: Text('All boots')),
                ...boots.map(
                  (boot) => PopupMenuItem(
                    value: boot.bootId,
                    child: Text(boot.displayName),
                  ),
                ),
              ];
            },
          ),
        );
      },
      loading: () => const SizedBox(
        width: 200,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: YaruCircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox(width: 200),
    );
  }
}
