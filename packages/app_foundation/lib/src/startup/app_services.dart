import 'package:app_foundation/src/config/config_reader.dart';
import 'package:app_foundation/src/error/config_error_app.dart';
import 'package:app_foundation/src/error/error_handlers.dart';
import 'package:app_foundation/src/error/error_reporter.dart';
import 'package:app_foundation/src/session/session_store.dart';
import 'package:app_foundation/src/settings/settings_repository.dart';
import 'package:app_foundation/src/startup/storage_migrations.dart';
import 'package:core/core.dart';
import 'package:database/database.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';
import 'package:networking/networking.dart';
import 'package:storage/storage.dart';

/// The app's infrastructure, created once at start-up.
///
/// This is the composition root shared by every app: each app then exposes
/// these objects through its own DI mechanism (Riverpod overrides or Bloc
/// `RepositoryProvider`s). Feature code receives what it needs through that
/// mechanism, never by reaching for this object.
final class AppServices {
  /// Wraps already-built services. The session store and settings repository
  /// are created from [secureStore] and [keyValueStore]. Prefer
  /// [AppServices.fromStores], which also builds the HTTP clients.
  new({
    required this.config,
    required this.keyValueStore,
    required this.secureStore,
    required this.database,
    required this.errorReporter,
    required this.apiClient,
    this.graphQLClient,
  }) : sessionStore = SessionStore(secureStore),
       settingsRepository = SettingsRepository(keyValueStore);

  /// Builds the HTTP clients from [config] and the session in [secureStore].
  factory fromStores({
    required AppConfig config,
    required KeyValueStore keyValueStore,
    required SecureStore secureStore,
    required AppDatabase database,
    required ErrorReporter errorReporter,
    HttpClientAdapter? httpClientAdapter,
  }) {
    final session = SessionStore(secureStore);
    final http = HttpSettings(
      readToken: session.readAccessToken,
      onUnauthorized: () async {
        Logger('Session').info('Access token rejected; clearing session');
        await session.clear();
      },
      enableLogging: config.networkLogs,
      logBodies: config.networkLogs,
      httpClientAdapter: httpClientAdapter,
    );
    return AppServices(
      config: config,
      keyValueStore: keyValueStore,
      secureStore: secureStore,
      database: database,
      errorReporter: errorReporter,
      apiClient: ApiClient.withSettings(
        baseUrl: config.apiBaseUrl,
        settings: http,
      ),
      graphQLClient: config.graphQLUrl == null
          ? null
          : GraphQLClient.create(endpoint: config.graphQLUrl!, settings: http),
    );
  }

  /// The validated build configuration.
  final AppConfig config;

  /// Non-secret persistent storage (preferences, small cached values).
  final KeyValueStore keyValueStore;

  /// Encrypted storage for secrets such as the access token.
  final SecureStore secureStore;

  /// The drift database for structured offline data.
  final AppDatabase database;

  /// Where unexpected errors are sent.
  final ErrorReporter errorReporter;

  /// REST client for `API_BASE_URL`, sending the session's access token.
  final ApiClient apiClient;

  /// `null` unless `GRAPHQL_URL` is configured.
  final GraphQLClient? graphQLClient;

  /// The user's credentials, stored in [secureStore].
  final SessionStore sessionStore;

  /// User preferences, stored in [keyValueStore].
  final SettingsRepository settingsRepository;

  /// A new cleaner that wipes all of the stores above.
  LocalDataCleaner get localDataCleaner => LocalDataCleaner(
    keyValueStore: keyValueStore,
    secureStore: secureStore,
    database: database,
  );

  /// Closes the database. Call when the app is torn down (for example in
  /// tests); the services must not be used afterwards.
  Future<void> dispose() => database.close();
}

final Logger _log = Logger('Startup');

/// Runs the start-up sequence shared by every app. Order matters:
///
/// 1. Flutter binding.
/// 2. Configuration: read and validate. An invalid configuration shows
///    [ConfigErrorApp] and returns `null` (fail fast).
/// 3. Logging, at the configured level.
/// 4. Global error handlers, so every later failure is reported.
/// 5. Storage: open the key-value store, secure store and database, and run
///    key-value migrations (database migrations run when it first opens).
///
/// The caller then runs its app with the returned services.
Future<AppServices?> initializeAppServices({
  ErrorReporter? errorReporter,
}) async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config;
  try {
    config = readAppConfig();
  } on ConfigException catch (exception) {
    debugPrint(exception.toString());
    runApp(ConfigErrorApp(exception));
    return null;
  }

  configureLogging(level: config.logLevel, sink: printLogRecord);
  _log.info('Starting $config');

  final reporter = errorReporter ?? LoggingErrorReporter();
  installErrorHandlers(reporter);

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

  return AppServices.fromStores(
    config: config,
    keyValueStore: keyValueStore,
    secureStore: secureStore,
    database: AppDatabase.open(),
    errorReporter: reporter,
  );
}
