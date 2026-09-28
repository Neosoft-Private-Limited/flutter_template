import 'package:meta/meta.dart';

/// A failure that crossed a layer boundary (network, storage, parsing...).
///
/// Failures are values: repositories return them inside a `Result` instead of
/// throwing, so the presentation layer can switch over them exhaustively.
///
/// [message] is a developer-facing description for logs. It must never contain
/// secrets or personal data and is not meant to be shown to users; map the
/// failure type to a localized string in the UI instead.
@immutable
sealed class AppFailure implements Exception {
  const new(this.message, {this.cause, this.stackTrace});

  final String message;

  /// The original error, kept for logging and crash reporting.
  final Object? cause;
  final StackTrace? stackTrace;

  /// Whether retrying the same operation later may succeed.
  bool get isTransient => false;

  /// Stable name used in logs (`runtimeType` is minified in release builds).
  String get kind;

  @override
  String toString() => '$kind($message)';
}

/// The device could not reach the server (offline, DNS, TLS handshake...).
final class NetworkFailure extends AppFailure {
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'NetworkFailure';

  @override
  bool get isTransient => true;
}

/// A connect, send or receive timeout elapsed.
final class TimeoutFailure extends AppFailure {
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'TimeoutFailure';

  @override
  bool get isTransient => true;
}

/// The operation was cancelled by the caller. Usually not shown to users.
final class CancelledFailure extends AppFailure {
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'CancelledFailure';
}

/// The server rejected the credentials (HTTP 401). Callers typically clear the
/// session and ask the user to sign in again.
final class UnauthorizedFailure extends AppFailure {
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'UnauthorizedFailure';
}

/// The server answered with an unexpected HTTP status code.
final class ServerFailure extends AppFailure {
  const new(
    super.message, {
    required this.statusCode,
    super.cause,
    super.stackTrace,
  });

  @override
  String get kind => 'ServerFailure';

  final int? statusCode;

  bool get isNotFound => statusCode == 404;

  @override
  bool get isTransient =>
      statusCode == 408 ||
      statusCode == 429 ||
      (statusCode != null && statusCode! >= 500);

  @override
  String toString() => '$kind($statusCode, $message)';
}

/// A payload did not match the expected shape.
final class ParsingFailure extends AppFailure {
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'ParsingFailure';
}

/// Reading from or writing to local storage failed.
final class StorageFailure extends AppFailure {
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'StorageFailure';
}

/// Input was rejected before any I/O happened.
final class ValidationFailure extends AppFailure {
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'ValidationFailure';
}

/// Anything that could not be classified. Always log these.
final class UnknownFailure extends AppFailure {
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'UnknownFailure';
}
