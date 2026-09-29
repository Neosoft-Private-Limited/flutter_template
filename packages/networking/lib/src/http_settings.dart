import 'package:dio/dio.dart';
import 'package:networking/src/interceptors/auth_interceptor.dart';
import 'package:networking/src/interceptors/logging_interceptor.dart';
import 'package:networking/src/interceptors/retry_interceptor.dart';

/// Transport settings shared by `ApiClient` (REST) and `GraphQLClient`, so
/// both use the same timeouts, auth, logging and retry policy.
final class HttpSettings {
  /// Settings with production-ready defaults: no auth, logging off, 15 s
  /// connect / 30 s send and receive timeouts and up to 2 retries.
  const new({
    this.readToken,
    this.onUnauthorized,
    this.enableLogging = false,
    this.logBodies = false,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.maxRetries = 2,
    this.httpClientAdapter,
  });

  /// Supplies the bearer token; `null` disables the auth interceptor.
  final TokenReader? readToken;

  /// Called when the server rejects the token.
  final Future<void> Function()? onUnauthorized;

  /// Adds the redacting `LoggingInterceptor`. Keep `false` in prod.
  final bool enableLogging;

  /// Also logs request and response bodies (redacted); only applies when
  /// [enableLogging] is `true`.
  final bool logBodies;

  /// Maximum time to establish a connection before a timeout failure.
  final Duration connectTimeout;

  /// Maximum time between bytes received before a timeout failure.
  final Duration receiveTimeout;

  /// Maximum time to send the request body before a timeout failure.
  final Duration sendTimeout;

  /// Retries per request for transient failures; `0` disables the retry
  /// interceptor. See `RetryInterceptor` for what is retried.
  final int maxRetries;

  /// Replaces the socket transport (tests use `FakeHttpAdapter`).
  final HttpClientAdapter? httpClientAdapter;

  /// Builds a Dio instance with the auth -> logging -> retry interceptor chain.
  Dio createDio({String baseUrl = ''}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: const {'Accept': 'application/json'},
      ),
    );
    if (httpClientAdapter != null) dio.httpClientAdapter = httpClientAdapter!;
    dio.interceptors.addAll([
      if (readToken != null)
        AuthInterceptor(readToken: readToken!, onUnauthorized: onUnauthorized),
      if (enableLogging) LoggingInterceptor(logBodies: logBodies),
      if (maxRetries > 0) RetryInterceptor(dio: dio, maxRetries: maxRetries),
    ]);
    return dio;
  }
}
