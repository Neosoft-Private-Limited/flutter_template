import 'package:core/src/result/app_failure.dart';
import 'package:meta/meta.dart';

/// The outcome of an operation that can fail in an expected way.
///
/// Use a `switch` to handle both cases:
///
/// ```dart
/// switch (await repository.fetchPosts()) {
///   case Ok(:final value): show(value);
///   case Err(:final failure): showError(failure);
/// }
/// ```
///
/// Unexpected programming errors should still throw; `Result` is for failures
/// the caller is expected to handle (offline, 404, invalid payload...).
@immutable
sealed class Result<T> {
  const new();

  const factory ok(T value) = Ok<T>;
  const factory err(AppFailure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value, or `null` for an [Err].
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err() => null,
  };

  /// The failure, or `null` for an [Ok].
  AppFailure? get failureOrNull => switch (this) {
    Ok() => null,
    Err(:final failure) => failure,
  };

  /// Transforms the value of an [Ok], passing an [Err] through unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok(:final value) => Ok(transform(value)),
    Err(:final failure) => Err(failure),
  };

  /// Returns the value of an [Ok] or throws the failure of an [Err].
  ///
  /// Useful inside Riverpod `AsyncNotifier`s, where a thrown failure becomes
  /// an `AsyncError` that the UI renders.
  T getOrThrow() => switch (this) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
}

final class Ok<T> extends Result<T> {
  const new(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const new(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) =>
      other is Err<T> && identical(other.failure, failure);

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Err($failure)';
}
