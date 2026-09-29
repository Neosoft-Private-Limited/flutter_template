import 'package:app_foundation/app_foundation.dart';
import 'package:core/core.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:networking/testing.dart';
import 'package:storage/storage.dart';

import 'helpers/pump.dart';

void main() {
  group('SettingsRepository', () {
    test('persists theme mode and locale', () async {
      final store = InMemoryKeyValueStore();
      final repository = SettingsRepository(store);

      expect(repository.themeMode, ThemeMode.system);
      expect(repository.locale, isNull);

      await repository.setThemeMode(ThemeMode.dark);
      await repository.setLocale(const Locale('es'));

      final reloaded = SettingsRepository(store);
      expect(reloaded.themeMode, ThemeMode.dark);
      expect(reloaded.locale, const Locale('es'));

      await reloaded.setThemeMode(ThemeMode.system);
      await reloaded.setLocale(null);
      expect(store.keys, isEmpty);
    });
  });

  group('AppServices.fromStores', () {
    AppServices build(Map<String, String> extra, FakeHttpAdapter adapter) {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      return AppServices.fromStores(
        config: AppConfig.fromMap({
          ConfigKeys.environment: 'dev',
          ConfigKeys.apiBaseUrl: 'https://api.test.dev',
          ...extra,
        }),
        keyValueStore: InMemoryKeyValueStore(),
        secureStore: InMemorySecureStore(),
        database: db,
        errorReporter: LoggingErrorReporter(),
        httpClientAdapter: adapter,
      );
    }

    test('creates a GraphQL client only when GRAPHQL_URL is set', () {
      final adapter = FakeHttpAdapter.always(FakeResponse.json({}));

      expect(build(const {}, adapter).graphQLClient, isNull);
      expect(
        build(const {
          ConfigKeys.graphQLUrl: 'https://gql.test.dev/graphql',
        }, adapter).graphQLClient?.endpoint,
        Uri.parse('https://gql.test.dev/graphql'),
      );
    });

    test('API calls carry the session token', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse.json({'ok': 1}));
      final services = build(const {}, adapter);
      await services.sessionStore.saveAccessToken('abc');

      await services.apiClient.get('ping', decode: (json) => json);

      expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
      expect(
        adapter.requests.single.uri.toString(),
        'https://api.test.dev/ping',
      );
    });

    test('a rejected token clears the session', () async {
      final services = build(
        const {},
        FakeHttpAdapter.always(const FakeResponse(401)),
      );
      await services.sessionStore.saveAccessToken('expired');

      await services.apiClient.get('me', decode: (json) => json);

      expect(await services.sessionStore.readAccessToken(), isNull);
    });
  });

  group('storageMigrations', () {
    test('v2 removes the legacy key-value posts cache', () async {
      final store = InMemoryKeyValueStore({
        StorageMigrator.installMarkerKey: true,
        StorageMigrator.versionKey: 1,
        'cache.posts.v1': '[]',
        'settings.theme_mode': 'dark',
      });

      final result = await StorageMigrator(
        store: store,
        secureStore: InMemorySecureStore(),
        migrations: storageMigrations,
      ).run();

      expect(result, const Ok(2));
      expect(store.containsKey('cache.posts.v1'), isFalse);
      expect(store.getString('settings.theme_mode'), 'dark');
    });
  });

  testWidgets('NotFoundPage calls onGoHome', (tester) async {
    var calls = 0;
    await pumpLocalized(tester, NotFoundPage(onGoHome: () => calls++));

    expect(find.text('Page not found'), findsWidgets);
    await tester.tap(find.text('Go to home'));

    expect(calls, 1);
  });
}
