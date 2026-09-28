import 'package:app/app/error/error_reporter.dart';
import 'package:app/app/session/session_store.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:networking/networking.dart';
import 'package:storage/storage.dart';

// Infrastructure providers: the composition root of the app.
//
// Providers that need asynchronous initialization (configuration, storage)
// throw by default and are supplied by `bootstrap` through ProviderScope
// overrides. Tests override the same providers with fakes, so there is no
// hidden global state and no service locator.

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError('keyValueStoreProvider must be overridden'),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => throw UnimplementedError('secureStoreProvider must be overridden'),
);

final errorReporterProvider = Provider<ErrorReporter>(
  (ref) => LoggingErrorReporter(),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(ref.watch(secureStoreProvider)),
);

final localDataCleanerProvider = Provider<LocalDataCleaner>(
  (ref) => LocalDataCleaner(
    keyValueStore: ref.watch(keyValueStoreProvider),
    secureStore: ref.watch(secureStoreProvider),
  ),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final session = ref.watch(sessionStoreProvider);
  return ApiClient.create(
    baseUrl: config.apiBaseUrl,
    readToken: session.readAccessToken,
    onUnauthorized: () async {
      Logger('Session').info('Access token rejected; clearing session');
      await session.clear();
    },
    enableLogging: config.networkLogs,
    logBodies: config.networkLogs,
  );
});
