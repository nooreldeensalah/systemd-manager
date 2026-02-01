import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/providers/systemd_provider.dart';

part 'units_provider.g.dart';

enum UnitStateFilter { all, active, inactive, failed }

class UnitsFilter {
  const UnitsFilter({
    this.searchQuery = '',
    this.typeFilter,
    this.stateFilter = UnitStateFilter.all,
    this.showOnlyLoaded = true,
  });

  final String searchQuery;
  final UnitType? typeFilter;
  final UnitStateFilter stateFilter;
  final bool showOnlyLoaded;

  UnitsFilter copyWith({
    String? searchQuery,
    UnitType? typeFilter,
    bool clearTypeFilter = false,
    UnitStateFilter? stateFilter,
    bool? showOnlyLoaded,
  }) {
    return UnitsFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      stateFilter: stateFilter ?? this.stateFilter,
      showOnlyLoaded: showOnlyLoaded ?? this.showOnlyLoaded,
    );
  }
}

@riverpod
class UnitsFilterNotifier extends _$UnitsFilterNotifier {
  @override
  UnitsFilter build() => const UnitsFilter();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(UnitType? type) {
    state = state.copyWith(typeFilter: type, clearTypeFilter: type == null);
  }

  void setStateFilter(UnitStateFilter filter) {
    state = state.copyWith(stateFilter: filter);
  }

  void clearFilters() {
    state = const UnitsFilter();
  }
}

@riverpod
AsyncValue<List<UnitInfo>> filteredUnits(Ref ref) {
  final filter = ref.watch(unitsFilterNotifierProvider);
  final unitsAsync = ref.watch(unitsProvider);

  return unitsAsync.whenData((units) {
    return units.where((unit) {
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        final nameMatch = unit.name.toLowerCase().contains(query);
        final descMatch = unit.description.toLowerCase().contains(query);
        if (!nameMatch && !descMatch) return false;
      }

      if (filter.typeFilter != null && unit.type != filter.typeFilter) {
        return false;
      }

      switch (filter.stateFilter) {
        case UnitStateFilter.all:
          break;
        case UnitStateFilter.active:
          if (!unit.activeState.isRunning) return false;
        case UnitStateFilter.inactive:
          if (!unit.activeState.isInactive) return false;
        case UnitStateFilter.failed:
          if (!unit.activeState.isFailed) return false;
      }

      if (filter.showOnlyLoaded && unit.loadState != UnitLoadState.loaded) {
        return false;
      }

      return true;
    }).toList();
  });
}

@riverpod
Future<UnitCounts> unitCounts(Ref ref) async {
  final units = await ref.watch(unitsProvider.future);

  var active = 0;
  var inactive = 0;
  var failed = 0;

  for (final unit in units) {
    if (unit.activeState.isRunning) {
      active++;
    } else if (unit.activeState.isFailed) {
      failed++;
    } else {
      inactive++;
    }
  }

  return UnitCounts(
    total: units.length,
    active: active,
    inactive: inactive,
    failed: failed,
  );
}

class UnitCounts {
  const UnitCounts({
    required this.total,
    required this.active,
    required this.inactive,
    required this.failed,
  });

  final int total;
  final int active;
  final int inactive;
  final int failed;
}

@riverpod
class SelectedUnit extends _$SelectedUnit {
  @override
  String? build() => null;

  void select(String? unitName) {
    state = unitName;
  }
}
