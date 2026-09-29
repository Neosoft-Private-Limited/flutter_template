import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:networking/src/error_mapper.dart';
import 'package:networking/src/http_settings.dart';
import 'package:networking/src/interceptors/auth_interceptor.dart';

/// Converts decoded JSON into a typed value. Throw a [FormatException] when
/// the payload does not have the expected shape.
typedef JsonDecoder<T> = T Function(Object? json);

/// The single HTTP entry point for feature code.
///
/// Every method returns a [Result]: transport, HTTP and parsing errors become
/// [AppFailure]s, so callers never have to catch Dio exceptions.
final class ApiClient {
  /// Wraps an existing [Dio] instance (useful in tests).
  new(Dio dio) : _dio = dio;

  /// Builds a client with the workspace defaults: JSON, timeouts and the
  /// auth -> logging -> retry interceptor chain (see [HttpSettings]).
  factory create({
    required Uri baseUrl,
    TokenReader? readToken,
    Future<void> Function()? onUnauthorized,
    bool enableLogging = false,
    bool logBodies = false,
    int maxRetries = 2,
    HttpClientAdapter? httpClientAdapter,
  }) => ApiClient.withSettings(
    baseUrl: baseUrl,
    settings: HttpSettings(
      readToken: readToken,
      onUnauthorized: onUnauthorized,
      enableLogging: enableLogging,
      logBodies: logBodies,
      maxRetries: maxRetries,
      httpClientAdapter: httpClientAdapter,
    ),
  );

  /// Builds a client from shared [HttpSettings].
  factory withSettings({required Uri baseUrl, required HttpSettings settings}) {
    // Dio concatenates baseUrl and relative paths verbatim, so
    // "https://api.dev" + "posts" would become "https://api.devposts".
    // Normalize to a trailing slash; request paths must then be relative
    // ("posts", not "/posts", which would drop any base path like "/v1").
    final base = baseUrl.path.endsWith('/')
        ? baseUrl
        : baseUrl.replace(path: '${baseUrl.path}/');
    return ApiClient(settings.createDio(baseUrl: base.toString()));
  }

  final Dio _dio;
  static final Logger _log = Logger('ApiClient');

  /// Sends a `GET` to [path] (relative to the base URL, no leading slash)
  /// and converts the JSON body with [decode].
  ///
  /// [query] becomes the query string; [options] can set per-request
  /// headers or `RequestExtras`. Transient failures are retried. Returns a
  /// `ParsingFailure` when [decode] throws a [FormatException], or the
  /// mapped [AppFailure] for transport and HTTP errors.
  Future<Result<T>> get<T>(
    String path, {
    required JsonDecoder<T> decode,
    Map<String, Object?>? query,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    path,
    method: 'GET',
    decode: decode,
    query: query,
    options: options,
    cancelToken: cancelToken,
  );

  /// Sends a `POST` with [body] (maps and lists are sent as JSON) and
  /// converts the response with [decode]. Parameters and errors are as for
  /// [get].
  ///
  /// Not retried unless [options] sets `RequestExtras.retryable` to `true`.
  Future<Result<T>> post<T>(
    String path, {
    required JsonDecoder<T> decode,
    Object? body,
    Map<String, Object?>? query,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    path,
    method: 'POST',
    decode: decode,
    body: body,
    query: query,
    options: options,
    cancelToken: cancelToken,
  );

  /// Sends a `PUT` with [body] (maps and lists are sent as JSON) and
  /// converts the response with [decode]. Parameters and errors are as for
  /// [get].
  ///
  /// Not retried unless [options] sets `RequestExtras.retryable` to `true`.
  Future<Result<T>> put<T>(
    String path, {
    required JsonDecoder<T> decode,
    Object? body,
    Map<String, Object?>? query,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    path,
    method: 'PUT',
    decode: decode,
    body: body,
    query: query,
    options: options,
    cancelToken: cancelToken,
  );

  /// Sends a `PATCH` with [body] (maps and lists are sent as JSON) and
  /// converts the response with [decode]. Parameters and errors are as for
  /// [get].
  ///
  /// Not retried unless [options] sets `RequestExtras.retryable` to `true`.
  Future<Result<T>> patch<T>(
    String path, {
    required JsonDecoder<T> decode,
    Object? body,
    Map<String, Object?>? query,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    path,
    method: 'PATCH',
    decode: decode,
    body: body,
    query: query,
    options: options,
    cancelToken: cancelToken,
  );

  /// Sends a `DELETE`, with an optional [body], and converts the response
  /// with [decode]. Parameters and errors are as for [get].
  ///
  /// Not retried unless [options] sets `RequestExtras.retryable` to `true`.
  Future<Result<T>> delete<T>(
    String path, {
    required JsonDecoder<T> decode,
    Object? body,
    Map<String, Object?>? query,
    Options? options,
    CancelToken? cancelToken,
  }) => _send(
    path,
    method: 'DELETE',
    decode: decode,
    body: body,
    query: query,
    options: options,
    cancelToken: cancelToken,
  );

  Future<Result<T>> _send<T>(
    String path, {
    required String method,
    required JsonDecoder<T> decode,
    Object? body,
    Map<String, Object?>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final Response<Object?> response;
    try {
      response = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(method: method),
      );
    } on DioException catch (error, stackTrace) {
      return Err(mapDioException(error, stackTrace));
    }

    try {
      return Ok(decode(response.data));
    } on FormatException catch (error, stackTrace) {
      _log.warning('Unexpected payload for $method $path', error);
      return Err(
        ParsingFailure(
          'Unexpected payload for $method $path: ${error.message}',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
