import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:networking/src/request_options_x.dart';

/// Logs HTTP traffic with sensitive headers, query parameters and JSON fields
/// masked by [Redactor].
///
/// Enable it only when `NETWORK_LOGS=true`; configuration validation rejects
/// that in prod. Bodies are logged only when [logBodies] is `true`.
final class LoggingInterceptor extends Interceptor {
  /// Logs to [logger] (default `Logger('Http')`): requests and responses at
  /// `FINE`, errors at `WARNING`. `clock` is used to time requests and can be
  /// replaced in tests.
  new({
    Logger? logger,
    this.redactor = const Redactor(),
    this.logBodies = false,
    DateTime Function()? clock,
  }) : _log = logger ?? Logger('Http'),
       _clock = clock ?? DateTime.now;

  final Logger _log;

  /// Masks sensitive headers, query parameters and JSON fields before they
  /// are logged.
  final Redactor redactor;

  /// Whether request and response bodies are logged (after redaction).
  final bool logBodies;
  final DateTime Function() _clock;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[RequestExtras.startedAt] = _clock();
    final attempt = options.extra[RequestExtras.retryAttempt] as int? ?? 0;
    _log.fine(() {
      final buffer = StringBuffer('--> ${options.method} ')
        ..write(redactor.uri(options.uri));
      if (attempt > 0) buffer.write(' (retry $attempt)');
      buffer.write('\n    headers: ${redactor.headers(options.headers)}');
      if (logBodies && options.data != null) {
        buffer.write('\n    body: ${redactor.json(options.data)}');
      }
      return buffer.toString();
    });
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log.fine(() {
      final buffer = StringBuffer(_summary(response.requestOptions))
        ..write(' ${response.statusCode}');
      if (logBodies && response.data != null) {
        buffer.write('\n    body: ${redactor.json(response.data)}');
      }
      return buffer.toString();
    });
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    _log.warning(
      '${_summary(err.requestOptions)} '
      '${status ?? err.type.name}',
    );
    handler.next(err);
  }

  String _summary(RequestOptions options) {
    final startedAt = options.extra[RequestExtras.startedAt] as DateTime?;
    final elapsed = startedAt == null
        ? ''
        : ' (${_clock().difference(startedAt).inMilliseconds} ms)';
    return '<-- ${options.method} ${redactor.uri(options.uri)}$elapsed';
  }
}
