import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base class for view models of screens that load data.
///
/// Implement [load] (usually one repository call returning a `Result`);
/// failures become an `AsyncError` that `BaseAsyncPage` renders with a retry
/// button. Add intent methods (submit, delete, ...) to the subclass.
///
/// ```dart
/// class ProfileViewModel extends AsyncViewModel<Profile> {
///   @override
///   Future<Result<Profile>> load() =>
///       ref.watch(profileRepositoryProvider).fetchProfile();
/// }
/// ```
///
/// Synchronous view models extend Riverpod's `Notifier<S>` directly and are
/// shown with `BasePage`.
abstract class AsyncViewModel<T> extends AsyncNotifier<T> {
  /// Loads the screen data. Called on first use and after [retry]/[refresh].
  Future<Result<T>> load();

  @override
  Future<T> build() async => (await load()).getOrThrow();

  /// Reloads while keeping the current data visible (pull to refresh).
  /// Completes when loading finishes; failures are exposed through
  /// [refreshError] rather than thrown.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Surfaced by `state` / refreshError.
    }
  }

  /// Reloads from scratch, showing the loading state (retry after an error).
  void retry() => ref.invalidateSelf();

  /// The error of a failed refresh while older data is still shown, or
  /// `null`.
  Object? get refreshError => state.hasValue ? state.error : null;
}
