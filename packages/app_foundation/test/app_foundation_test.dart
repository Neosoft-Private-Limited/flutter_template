import 'package:app_foundation/app_foundation.dart';
import 'package:core/core.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';
import 'package:storage/storage.dart';

void main() {
  group('FailureMessages', () {
    late AppLocalizations l10n;

    setUpAll(
      () async =>
          l10n = await AppLocalizations.delegate.load(const Locale('en')),
    );

    test('maps each failure type to a user-facing message', () {
      expect(l10n.describeError(const NetworkFailure('x')), l10n.errorNetwork);
      expect(l10n.describeError(const TimeoutFailure('x')), l10n.errorTimeout);
      expect(
        l10n.describeError(const UnauthorizedFailure('x')),
        l10n.errorUnauthorized,
      );
      expect(
        l10n.describeError(const NotFoundFailure('x')),
        l10n.errorNotFound,
      );
      expect(l10n.describeError(const GraphQLFailure('x')), l10n.errorServer);
      expect(
        l10n.describeError(const ServerFailure('x', statusCode: 500)),
        l10n.errorServer,
      );
      expect(l10n.describeError(const ParsingFailure('x')), l10n.errorParsing);
      expect(l10n.describeError(StateError('bug')), l10n.errorUnknown);
    });

    test('maps validation errors', () {
      expect(
        l10n.describeValidation(ValidationError.tooShort, minLength: 3),
        'Use at least 3 characters',
      );
    });
  });

  group('SessionStore and LocalDataCleaner', () {
    test('stores the access token in secure storage only', () async {
      final secure = InMemorySecureStore();
      final session = SessionStore(secure);

      await session.saveAccessToken('abc');
      expect(await session.readAccessToken(), 'abc');
      expect(secure.values, {SessionStore.accessTokenKey: 'abc'});

      await session.clear();
      expect(await session.readAccessToken(), isNull);
    });

    test('clears the database too', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await db.postsDao.replaceAll([
        CachedPostsCompanion.insert(
          id: const Value(1),
          userId: 1,
          title: 't',
          body: 'b',
          cachedAt: DateTime.utc(2026),
        ),
      ]);

      await LocalDataCleaner(
        keyValueStore: InMemoryKeyValueStore(),
        secureStore: InMemorySecureStore(),
        database: db,
      ).clearAll();

      expect(await db.postsDao.getAll(), isEmpty);
    });

    test('clears everything except storage bookkeeping', () async {
      final store = InMemoryKeyValueStore({
        StorageMigrator.versionKey: 3,
        StorageMigrator.installMarkerKey: true,
        'settings.theme_mode': 'dark',
        'cache.posts.v1': '[]',
      });
      final secure = InMemorySecureStore({'a': '1'});

      await LocalDataCleaner(
        keyValueStore: store,
        secureStore: secure,
      ).clearAll();

      expect(store.keys, {
        StorageMigrator.versionKey,
        StorageMigrator.installMarkerKey,
      });
      expect(secure.values, isEmpty);
    });
  });

  testWidgets('ConfigErrorApp lists every configuration problem', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ConfigErrorApp(
        ConfigException(['API_BASE_URL is not set.', 'APP_ENV is not set.']),
      ),
    );

    expect(find.text('Invalid build configuration'), findsOneWidget);
    expect(find.text('- API_BASE_URL is not set.'), findsOneWidget);
    expect(find.text('- APP_ENV is not set.'), findsOneWidget);
  });

  test('English strings are the fallback locale', () {
    expect(AppLocalizations.supportedLocales.first.languageCode, 'en');
  });
}
