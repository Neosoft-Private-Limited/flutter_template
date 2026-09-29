import 'dart:developer' as developer;

import 'package:app_foundation/src/error/error_reporter.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

/// Routes framework errors and uncaught asynchronous errors to [reporter],
/// and replaces the red error box with a neutral placeholder in release.
void installErrorHandlers(ErrorReporter reporter) {
  // Errors thrown inside the Flutter framework (build, layout, paint...).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reporter.recordFlutterError(details);
  };

  // Uncaught asynchronous errors outside the framework.
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    reporter.recordError(error, stackTrace, fatal: true);
    return true;
  };

  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const Center(
      child: Icon(Icons.error_outline, size: 32, color: Color(0xFF9E9E9E)),
    );
  }
}

/// Log sink: readable lines in debug, `dart:developer` otherwise.
void printLogRecord(LogRecord record) {
  if (kDebugMode) {
    // Visible in `flutter run` output and IDE consoles.
    debugPrint(formatLogRecord(record));
  } else {
    developer.log(
      record.message,
      name: record.loggerName,
      level: record.level.value,
      time: record.time,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}
