import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:networking/src/error_mapper.dart';
import 'package:networking/src/http_settings.dart';
import 'package:networking/src/request_options_x.dart';

/// Converts the `data` object of a GraphQL response into a typed value.
/// Throw a [FormatException] when the shape is unexpected.
typedef GraphQLDecoder<T> = T Function(Map<String, Object?> data);

/// A minimal GraphQL-over-HTTP client that returns [Result] values.
///
/// It runs on the same Dio stack as `ApiClient`, so the auth, logging
/// (redacted) and retry interceptors apply. Queries are retried like `GET`
/// requests; mutations are never retried automatically.
///
/// Error policy:
/// - transport and HTTP errors map like REST calls (`NetworkFailure`, ...);
/// - a response with `errors` becomes a [GraphQLFailure], or an
///   [UnauthorizedFailure] when an error has the code `UNAUTHENTICATED`
///   (which also triggers `onUnauthorized`);
/// - partial data alongside `errors` is treated as a failure.
///
/// Normalized caching, subscriptions and code-generated types are out of
/// scope; see docs/architecture.md#graphql for when to adopt a full client.
final class GraphQLClient {
  /// Wraps an existing [Dio] instance that posts to [endpoint].
  new(this._dio, {required this.endpoint, this._onUnauthorized});

  /// Builds a client for [endpoint] from shared [HttpSettings].
  factory create({
    required Uri endpoint,
    HttpSettings settings = const HttpSettings(),
  }) => GraphQLClient(
    settings.createDio(),
    endpoint: endpoint,
    onUnauthorized: settings.onUnauthorized,
  );

  final Dio _dio;

  /// The absolute GraphQL endpoint every operation is posted to.
  final Uri endpoint;
  final Future<void> Function()? _onUnauthorized;

  static final Logger _log = Logger('GraphQLClient');

  /// The `extensions.code` that maps an error to [UnauthorizedFailure].
  static const unauthenticatedCode = 'UNAUTHENTICATED';

  /// Runs a query. Queries have no side effects, so transient failures are
  /// retried by the retry interceptor.
  Future<Result<T>> query<T>(
    String document, {
    required GraphQLDecoder<T> decode,
    Map<String, Object?>? variables,
    String? operationName,
    CancelToken? cancelToken,
  }) => _send(
    document,
    decode: decode,
    variables: variables,
    operationName: operationName,
    cancelToken: cancelToken,
    retryable: true,
  );

  /// Runs a mutation. Never retried automatically.
  Future<Result<T>> mutate<T>(
    String document, {
    required GraphQLDecoder<T> decode,
    Map<String, Object?>? variables,
    String? operationName,
    CancelToken? cancelToken,
  }) => _send(
    document,
    decode: decode,
    variables: variables,
    operationName: operationName,
    cancelToken: cancelToken,
    retryable: false,
  );

  Future<Result<T>> _send<T>(
    String document, {
    required GraphQLDecoder<T> decode,
    required bool retryable,
    Map<String, Object?>? variables,
    String? operationName,
    CancelToken? cancelToken,
  }) async {
    final operation = operationName ?? 'anonymous operation';
    final Response<Object?> response;
    try {
      response = await _dio.postUri<Object?>(
        endpoint,
        data: {
          'query': document,
          'variables': ?variables,
          'operationName': ?operationName,
        },
        cancelToken: cancelToken,
        options: Options(
          contentType: Headers.jsonContentType,
          extra: {RequestExtras.retryable: retryable},
        ),
      );
    } on DioException catch (error, stackTrace) {
      return Err(mapDioException(error, stackTrace));
    }

    final body = response.data;
    if (body is! Map<String, Object?>) {
      return Err(
        ParsingFailure('GraphQL $operation: response is not an object'),
      );
    }

    if (body['errors'] case final List<Object?> errors when errors.isNotEmpty) {
      final messages = <String>[];
      final codes = <String>[];
      for (final error in errors) {
        if (error case {'message': final String message}) messages.add(message);
        if (error case {'extensions': {'code': final String code}}) {
          codes.add(code);
        }
      }
      _log.warning('GraphQL $operation failed: ${codes.join(', ')}');
      if (codes.contains(unauthenticatedCode)) {
        await _onUnauthorized?.call();
        return Err(UnauthorizedFailure('GraphQL $operation: unauthenticated'));
      }
      return Err(
        GraphQLFailure(
          'GraphQL $operation returned ${errors.length} error(s)',
          errors: messages,
          codes: codes,
        ),
      );
    }

    final data = body['data'];
    if (data is! Map<String, Object?>) {
      return Err(ParsingFailure('GraphQL $operation: missing "data"'));
    }
    try {
      return Ok(decode(data));
    } on FormatException catch (error, stackTrace) {
      return Err(
        ParsingFailure(
          'Unexpected payload for GraphQL $operation: ${error.message}',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
