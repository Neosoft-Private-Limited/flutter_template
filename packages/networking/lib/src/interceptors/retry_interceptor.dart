import 'dart:async';

import 'package:dio/dio.dart';
import 'package:networking/src/request_options_x.dart';

/// Retries transient failures of idempotent requests with exponential backoff.
///
/// Only `GET`, `HEAD` and `OPTIONS` are retried by default. `POST`, `PUT`,
/// `PATCH` and `DELETE` are retried only when the request sets
/// `RequestExtras.retryable` to `true`, because repeating them can duplicate
/// side effects unless the backend is designed for it.
///
/// Retried conditions: connection errors, timeouts, and HTTP 408, 429, 502,
/// 503 and 504. Cancelled requests are never retried.
final class RetryInterceptor extends Interceptor {
  /// Creates an interceptor that re-sends failed requests through `dio`.
  ///
  /// Attempt `n` (zero-based) waits `baseDelay * 2^n` before retrying.
  /// `sleep` replaces [Future.delayed] so tests can skip the waits.
  new({
    required this._dio,
    this.maxRetries = 2,
    this.baseDelay = const Duration(milliseconds: 400),
    Future<void> Function(Duration delay)? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed;

  final Dio _dio;

  /// Maximum number of retries after the first attempt; defaults to 2.
  final int maxRetries;

  /// Delay before the first retry, doubled for each further retry.
  final Duration baseDelay;
  final Future<void> Function(Duration delay) _sleep;

  /// HTTP methods retried without opting in via `RequestExtras.retryable`.
  static const Set<String> idempotentMethods = {'GET', 'HEAD', 'OPTIONS'};

  /// HTTP status codes treated as transient and therefore retried.
  static const Set<int> retryableStatusCodes = {408, 429, 502, 503, 504};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = options.extra[RequestExtras.retryAttempt] as int? ?? 0;

    if (attempt >= maxRetries || !_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    await _sleep(baseDelay * (1 << attempt));
    if (options.cancelToken?.isCancelled ?? false) {
      handler.next(err);
      return;
    }

    options.extra[RequestExtras.retryAttempt] = attempt + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _shouldRetry(DioException err) {
    final options = err.requestOptions;
    final methodAllowed =
        idempotentMethods.contains(options.method.toUpperCase()) ||
        (options.extra[RequestExtras.retryable] as bool? ?? false);
    if (!methodAllowed) return false;

    return switch (err.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => true,
      DioExceptionType.badResponse => retryableStatusCodes.contains(
        err.response?.statusCode,
      ),
      _ => false,
    };
  }
}
