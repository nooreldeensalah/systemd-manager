import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:systemd_manager/journal/widgets/widgets.dart';
import 'package:systemd_manager/providers/providers.dart';
import 'package:systemd_manager/widgets/widgets.dart';

class JournalPage extends ConsumerStatefulWidget {
  const JournalPage({super.key});

  @override
  ConsumerState<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends ConsumerState<JournalPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          JournalHeader(
            searchController: _searchController,
            onSearch: _applySearch,
          ),
          const Divider(height: 1),
          Expanded(child: PagedLogView(scrollController: _scrollController)),
        ],
      ),
    );
  }

  void _applySearch() {
    final query = _searchController.text.trim();
    ref
        .read(journalFilterNotifierProvider.notifier)
        .setSearchText(query.isEmpty ? null : query);
  }
}

class PagedLogView extends ConsumerWidget {
  const PagedLogView({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the controller state
    final logsAsync = ref.watch(journalControllerProvider);
    // Watch the controller NOTIFIER for manual actions (like stack check)
    final controller = ref.watch(journalControllerProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: logsAsync.when(
            data: (logs) =>
                LogListView(logs: logs, scrollController: scrollController),
            loading: () => const LoadingView(),
            // We can show the previous data while loading if we want,
            // but for pagination, a clear "loading" state is often better to avoid confusion.
            error: (error, stack) => ErrorView(
              message: 'Failed to load logs',
              details: error.toString(),
              onRetry: () =>
                  ref.read(journalControllerProvider.notifier).refresh(),
            ),
          ),
        ),
        _buildPaginationBar(context, ref, controller, logsAsync.isLoading),
      ],
    );
  }

  Widget _buildPaginationBar(
    BuildContext context,
    WidgetRef ref,
    JournalController controller,
    bool isLoading,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Newer Logs (Previous in terms of our stack)
          ElevatedButton.icon(
            onPressed: isLoading || !controller.canGoBack
                ? null
                : () => controller.previousPage(),
            icon: const Icon(Icons.arrow_back),
            label: const Text(
              'Newer',
            ), // "Back" typically means "Newer" if we are going deep in history
          ),

          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),

          // Older Logs (Next page)
          ElevatedButton.icon(
            onPressed: isLoading ? null : () => controller.nextPage(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Older'),
          ),
        ],
      ),
    );
  }
}
