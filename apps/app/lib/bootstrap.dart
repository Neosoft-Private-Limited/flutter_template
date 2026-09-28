import 'dart:async';
import 'dart:developer' as developer;

import 'package:app/app/app.dart';
import 'package:app/app/config/config_reader.dart';
import 'package:app/app/di/providers.dart';
import 'package:app/app/error/config_error_app.dart';
import 'package:app/app/error/error_reporter.dart';
import 'package:app/app/storage_migrations.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:storage/storage.dart';

final Logger _log = Logger('Bootstrap');

/// Starts the app. Order matters:
///
/// 1. Flutter binding.
/// 2. Configuration: read and validate; an invalid configuration shows
///    [ConfigErrorApp] and stops here (fail fast).
/// 3. Logging, at the configured level.
/// 4. Global error handlers, so every later failure is reported.
/// 5. Storage: open stores and run migrations.
/// 6. `runApp` with the infrastructure supplied to Riverpod.
Future<void> bootstrap({ErrorReporter? errorReporter}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config;
  try {
    config = readAppConfig();
  } on ConfigException catch (exception) {
    debugPrint(exception.toString());
    runApp(ConfigErrorApp(exception));
    return;
  }

  configureLogging(level: config.logLevel, sink: _printLogRecord);
  _log.info('Starting $config');

  final reporter = errorReporter ?? LoggingErrorReporter();
  _installErrorHandlers(reporter);

  final keyValueStore = await SharedPreferencesKeyValueStore.create();
  final secureStore = FlutterSecureStore();
  final migration = await StorageMigrator(
    store: keyValueStore,
    secureStore: secureStore,
    migrations: storageMigrations,
  ).run();
  if (migration case Err(:final failure)) {
    // Keep starting: the app can usually work with partially migrated data.
    // Decide per migration whether that is acceptable for your app.
    reporter.recordError(failure, failure.stackTrace, reason: failure.message);
  }

  runApp(
    ProviderScope(
      // Retries are explicit (network retry interceptor, user-triggered
      // retry buttons); disable Riverpod's automatic provider retry.
      retry: (_, _) => null,
      overrides: [
        appConfigProvider.overrideWithValue(config),
        keyValueStoreProvider.overrideWithValue(keyValueStore),
        secureStoreProvider.overrideWithValue(secureStore),
        errorReporterProvider.overrideWithValue(reporter),
      ],
      child: const App(),
    ),
  );
}

void _installErrorHandlers(ErrorReporter reporter) {
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

  // Release builds show a neutral placeholder instead of the red error box
  // when a widget fails to build.
  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const Center(
      child: Icon(Icons.error_outline, size: 32, color: Color(0xFF9E9E9E)),
    );
  }
}

void _printLogRecord(LogRecord record) {
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
