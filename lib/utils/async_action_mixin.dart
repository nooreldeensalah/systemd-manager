import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

/// A version of the mixin for AsyncNotifier which already holds [AsyncValue] state natively.
mixin AsyncNotifierActionMixin<T> on AutoDisposeAsyncNotifier<T> {
  Logger get logger;

  /// Safely executes an async [action], managing [AsyncLoading] and [AsyncError] states.
  ///
  /// If [action] succeeds, the state is restored from its current value (as it might
  /// have been updated imperatively within the action or via invalidation).
  Future<void> guardAsync(
    Future<void> Function() action, {
    String? errorMessage,
  }) async {
    final previousState = state;
    state = AsyncLoading<T>();

    try {
      await action();
      // If the action finished successfully, we try to preserve the state
      // which might have been updated by 'ref.invalidate' or imperative updates.
      // If state is still loading (meaning no one updated it), we restore previous data.
      if (state is AsyncLoading) {
        state = previousState;
      }
    } on Object catch (error, stackTrace) {
      state = AsyncError<T>(error, stackTrace);
      logger.error(
        errorMessage ?? 'Async action failed',
        error,
        stackTrace,
      );
    }
  }
}
