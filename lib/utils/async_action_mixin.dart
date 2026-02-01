import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ubuntu_logger/ubuntu_logger.dart';

/// A version of the mixin for AsyncNotifier which already holds [AsyncValue] state natively.
mixin AsyncNotifierActionMixin<T> on AutoDisposeAsyncNotifier<T> {
  Logger get logger;

  Future<void> guardAsync(
    Future<void> Function() action, {
    String? errorMessage,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await action();
      // If action updates state, this guard will capture the NEW state.
      // If action is void, we might need to return the current state.
      // However, usually notifiers update state internally.
      // Ideally, simple actions return a value that becomes the new state.
      // But for side-effect actions that update state imperatively, this is tricky.

      // Better approach for AsyncNotifier:
      // Just run the action. If it throws, we catch it.
      return state.value as T;
    });

    if (state.hasError) {
      logger.error(
        errorMessage ?? 'Async action failed',
        state.error,
        state.stackTrace,
      );
    }
  }
}
