import 'package:core/core.dart';
import 'package:dio/dio.dart';

/// Converts a [DioException] into the workspace-wide [AppFailure] taxonomy.
///
/// Messages are developer-facing and contain no request/response bodies.
AppFailure mapDioException(DioException error, [StackTrace? stackTrace]) {
  final trace = stackTrace ?? error.stackTrace;
  final request =
      '${error.requestOptions.method} '
      '${error.requestOptions.uri.path}';

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => TimeoutFailure(
      '$request timed out (${error.type.name})',
      cause: error,
      stackTrace: trace,
    ),
    DioExceptionType.cancel => CancelledFailure(
      '$request was cancelled',
      cause: error,
      stackTrace: trace,
    ),
    DioExceptionType.connectionError => NetworkFailure(
      '$request could not connect',
      cause: error,
      stackTrace: trace,
    ),
    DioExceptionType.badCertificate => NetworkFailure(
      '$request failed certificate validation',
      cause: error,
      stackTrace: trace,
    ),
    DioExceptionType.badResponse => _mapStatus(error, request, trace),
    DioExceptionType.unknown => UnknownFailure(
      '$request failed: ${error.error.runtimeType}',
      cause: error,
      stackTrace: trace,
    ),
  };
}

AppFailure _mapStatus(DioException error, String request, StackTrace trace) {
  final status = error.response?.statusCode;
  if (status == 401) {
    return UnauthorizedFailure(
      '$request returned 401',
      cause: error,
      stackTrace: trace,
    );
  }
  return ServerFailure(
    '$request returned $status',
    statusCode: status,
    cause: error,
    stackTrace: trace,
  );
}
