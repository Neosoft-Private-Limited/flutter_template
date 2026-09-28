import 'package:dio/dio.dart';
import 'package:networking/src/request_options_x.dart';

/// Reads the current access token, or `null` when signed out.
typedef TokenReader = Future<String?> Function();

/// Attaches `Authorization: Bearer <token>` to outgoing requests and reports
/// HTTP 401 responses through the `onUnauthorized` callback.
///
/// Token refresh is backend-specific and intentionally not implemented; add it
/// here (as a `QueuedInterceptor`) once your API defines the refresh flow.
final class AuthInterceptor extends Interceptor {
  new({required this._readToken, this._onUnauthorized});

  final TokenReader _readToken;
  final Future<void> Function()? _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final shouldAuthenticate =
        options.extra[RequestExtras.authenticate] as bool? ?? true;
    if (shouldAuthenticate && !options.headers.containsKey('Authorization')) {
      final token = await _readToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _onUnauthorized?.call();
    }
    handler.next(err);
  }
}
