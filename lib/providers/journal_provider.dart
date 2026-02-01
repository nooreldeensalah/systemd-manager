import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:systemd_manager/models/models.dart';
import 'package:systemd_manager/providers/systemd_provider.dart';
import 'package:systemd_manager/services/services.dart';
import 'package:systemd_manager/utils/async_action_mixin.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

part 'journal_provider.g.dart';

final _log = Logger('JournalProvider');

@riverpod
JournalService journalService(Ref ref) {
  throw UnimplementedError('journalService must be overridden');
}

@riverpod
class JournalFilterNotifier extends _$JournalFilterNotifier {
  @override
  JournalFilter build() => const JournalFilter();

  void setUnitName(String? unitName) =>
      state = state.copyWith(unitName: unitName, cursor: null);

  void setMinPriority(JournalPriority priority) =>
      state = state.copyWith(minPriority: priority, cursor: null);

  void setSince(DateTime? since) =>
      state = state.copyWith(since: since, cursor: null);

  void setBootId(String? bootId) =>
      state = state.copyWith(bootId: bootId, cursor: null);

  void setSearchText(String? searchText) =>
      state = state.copyWith(searchText: searchText, cursor: null);

  void setLimit(int limit) =>
      state = state.copyWith(limit: limit, cursor: null);

  void setCursor(String? cursor) => state = state.copyWith(cursor: cursor);

  void clearFilters() => state = const JournalFilter();
}

@riverpod
class JournalController extends _$JournalController
    with AsyncNotifierActionMixin<List<JournalEntry>> {
  @override
  Logger get logger => _log;

  final List<String?> _cursorStack = [];

  @override
  Future<List<JournalEntry>> build() async {
    final filter = ref.watch(journalFilterNotifierProvider);

    if (filter.cursor == null) {
      _cursorStack.clear();
    }

    final service = ref.watch(journalServiceProvider);
    return service.query(filter);
  }

  bool get canGoBack => _cursorStack.isNotEmpty;

  Future<void> nextPage() async {
    await guardAsync(() async {
      final currentList = state.value;
      if (currentList == null || currentList.isEmpty) return;

      final lastCursor = currentList.last.cursor;
      if (lastCursor == null) return;

      final filter = ref.read(journalFilterNotifierProvider);
      _cursorStack.add(filter.cursor);
      ref.read(journalFilterNotifierProvider.notifier).setCursor(lastCursor);
    }, errorMessage: 'Failed to load next page');
  }

  Future<void> previousPage() async {
    await guardAsync(() async {
      if (_cursorStack.isEmpty) return;

      final prevCursor = _cursorStack.removeLast();
      ref.read(journalFilterNotifierProvider.notifier).setCursor(prevCursor);
    }, errorMessage: 'Failed to load previous page');
  }

  Future<void> refresh() async {
    await guardAsync(() async {
      ref.invalidateSelf();
    }, errorMessage: 'Failed to refresh logs');
  }

  void reset() {
    _cursorStack.clear();
    ref.read(journalFilterNotifierProvider.notifier).setCursor(null);
  }
}

@riverpod
Future<List<JournalEntry>> unitJournalEntries(
  Ref ref,
  String unitName, {
  int limit = 100,
}) async {
  final service = ref.watch(journalServiceProvider);
  return service.queryUnit(unitName, limit: limit);
}

@riverpod
Future<List<BootRecord>> availableBoots(Ref ref) async {
  final service = ref.watch(journalServiceProvider);
  return service.listBoots();
}

@riverpod
Future<JournalDiskUsage> journalDiskUsage(Ref ref) async {
  final service = ref.watch(journalServiceProvider);
  return service.getDiskUsage();
}

/// Provider to get unique unit names from recent journal entries for autocomplete
@riverpod
Future<List<String>> journalUnitNames(Ref ref) async {
  final units = await ref.watch(unitsProvider.future);
  final unitFiles = await ref.watch(unitFilesProvider.future);

  final names = <String>{
    ...units.map((u) => u.name),
    ...unitFiles.map((u) => u.name),
  };

  return names.toList()..sort();
}
