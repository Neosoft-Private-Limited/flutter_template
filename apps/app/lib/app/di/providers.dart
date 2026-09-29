import 'package:app_foundation/app_foundation.dart';
import 'package:core/core.dart';
import 'package:database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:networking/networking.dart';
import 'package:storage/storage.dart';

// Infrastructure providers: the Riverpod view of `AppServices`.
//
// Providers whose values are created at start-up throw by default and are
// supplied through ProviderScope overrides (see `overridesFor`). Tests
// override the same providers with fakes, so there is no hidden global state
// and no service locator.

final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError('appConfigProvider must be overridden'),
);

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => throw UnimplementedError('keyValueStoreProvider must be overridden'),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => throw UnimplementedError('secureStoreProvider must be overridden'),
);

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => throw UnimplementedError('apiClientProvider must be overridden'),
);

/// `null` unless `GRAPHQL_URL` is configured.
final graphQLClientProvider = Provider<GraphQLClient?>((ref) => null);

final errorReporterProvider = Provider<ErrorReporter>(
  (ref) => LoggingErrorReporter(),
);

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(ref.watch(secureStoreProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(keyValueStoreProvider)),
);

final localDataCleanerProvider = Provider<LocalDataCleaner>(
  (ref) => LocalDataCleaner(
    keyValueStore: ref.watch(keyValueStoreProvider),
    secureStore: ref.watch(secureStoreProvider),
    database: ref.watch(databaseProvider),
  ),
);

/// Supplies every infrastructure provider from [services].
List<Override> overridesFor(AppServices services) => [
  appConfigProvider.overrideWithValue(services.config),
  keyValueStoreProvider.overrideWithValue(services.keyValueStore),
  secureStoreProvider.overrideWithValue(services.secureStore),
  databaseProvider.overrideWithValue(services.database),
  apiClientProvider.overrideWithValue(services.apiClient),
  graphQLClientProvider.overrideWithValue(services.graphQLClient),
  errorReporterProvider.overrideWithValue(services.errorReporter),
];
