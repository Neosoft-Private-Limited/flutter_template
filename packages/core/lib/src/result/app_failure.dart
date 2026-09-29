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
  /// Creates a failure described by [message], optionally wrapping the
  /// original [cause] and where it was thrown ([stackTrace]).
  const new(this.message, {this.cause, this.stackTrace});

  /// Developer-facing description for logs. Must not contain secrets or
  /// personal data, and is never shown to users.
  final String message;

  /// The original error, kept for logging and crash reporting.
  final Object? cause;

  /// Where [cause] was thrown, or `null` when it was not captured.
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
  /// Creates a network failure; see [AppFailure.new].
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'NetworkFailure';

  @override
  bool get isTransient => true;
}

/// A connect, send or receive timeout elapsed.
final class TimeoutFailure extends AppFailure {
  /// Creates a timeout failure; see [AppFailure.new].
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'TimeoutFailure';

  @override
  bool get isTransient => true;
}

/// The operation was cancelled by the caller. Usually not shown to users.
final class CancelledFailure extends AppFailure {
  /// Creates a cancellation failure; see [AppFailure.new].
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'CancelledFailure';
}

/// The server rejected the credentials (HTTP 401). Callers typically clear the
/// session and ask the user to sign in again.
final class UnauthorizedFailure extends AppFailure {
  /// Creates an unauthorized failure; see [AppFailure.new].
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'UnauthorizedFailure';
}

/// The requested resource does not exist (HTTP 404, or a GraphQL field that
/// resolved to `null`). Transport-neutral so the UI handles both the same way.
final class NotFoundFailure extends AppFailure {
  /// Creates a not-found failure; see [AppFailure.new].
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'NotFoundFailure';
}

/// The server answered with an unexpected HTTP status code.
final class ServerFailure extends AppFailure {
  /// Creates a server failure for the response's [statusCode]; see
  /// [AppFailure.new] for the other parameters.
  const new(
    super.message, {
    required this.statusCode,
    super.cause,
    super.stackTrace,
  });

  @override
  String get kind => 'ServerFailure';

  /// The HTTP status code, or `null` when the response had none. 408, 429
  /// and 5xx make the failure [isTransient].
  final int? statusCode;

  @override
  bool get isTransient =>
      statusCode == 408 ||
      statusCode == 429 ||
      (statusCode != null && statusCode! >= 500);

  @override
  String toString() => '$kind($statusCode, $message)';
}

/// A GraphQL response contained `errors`.
///
/// [errors] holds the error messages and [codes] the `extensions.code` values
/// (for example `BAD_USER_INPUT`). Messages come from the server: log them,
/// but show users a localized message instead.
final class GraphQLFailure extends AppFailure {
  /// Creates a GraphQL failure from the response's [errors] and [codes];
  /// see [AppFailure.new] for the other parameters.
  const new(
    super.message, {
    this.errors = const [],
    this.codes = const [],
    super.cause,
    super.stackTrace,
  });

  /// The `message` of each GraphQL error, as sent by the server. Log-only.
  final List<String> errors;

  /// The `extensions.code` values present on the errors (for example
  /// `BAD_USER_INPUT`). Errors without a code are omitted.
  final List<String> codes;

  @override
  String get kind => 'GraphQLFailure';
}

/// A payload did not match the expected shape.
final class ParsingFailure extends AppFailure {
  /// Creates a parsing failure; see [AppFailure.new].
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'ParsingFailure';
}

/// Reading from or writing to local storage failed.
final class StorageFailure extends AppFailure {
  /// Creates a storage failure; see [AppFailure.new].
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'StorageFailure';
}

/// Input was rejected before any I/O happened.
final class ValidationFailure extends AppFailure {
  /// Creates a validation failure; see [AppFailure.new].
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'ValidationFailure';
}

/// Anything that could not be classified. Always log these.
final class UnknownFailure extends AppFailure {
  /// Creates an unclassified failure; see [AppFailure.new].
  const new(super.message, {super.cause, super.stackTrace});

  @override
  String get kind => 'UnknownFailure';
}
