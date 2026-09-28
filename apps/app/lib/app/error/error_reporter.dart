import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Destination for unexpected errors (uncaught exceptions, framework errors).
///
/// The default implementation only logs. To add crash reporting, implement
/// this interface with your vendor's SDK and pass it to `bootstrap`; nothing
/// else in the app needs to change.
abstract interface class ErrorReporter {
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  void recordFlutterError(FlutterErrorDetails details);
}

/// Logs errors through `package:logging` at SEVERE level.
final class LoggingErrorReporter implements ErrorReporter {
  static final Logger _log = Logger('ErrorReporter');

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    final kind = fatal ? 'Uncaught' : 'Handled';
    _log.severe(
      reason == null ? '$kind error' : '$kind error: $reason',
      error,
      stackTrace,
    );
  }

  @override
  void recordFlutterError(FlutterErrorDetails details) {
    _log.severe(
      'Flutter error: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  }
}
