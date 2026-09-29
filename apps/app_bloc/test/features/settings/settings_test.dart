import 'package:app_bloc/features/settings/cubit/settings_cubits.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:storage/storage.dart';

import '../../helpers/test_app.dart';

void main() {
  group('ThemeCubit', () {
    late InMemoryKeyValueStore store;

    setUp(
      () => store = InMemoryKeyValueStore({
        SettingsRepository.themeModeKey: 'light',
      }),
    );

    test('starts from the stored value', () {
      final cubit = ThemeCubit(SettingsRepository(store));
      addTearDown(cubit.close);

      expect(cubit.state, ThemeMode.light);
    });

    blocTest<ThemeCubit, ThemeMode>(
      'persists the selected mode',
      build: () => ThemeCubit(SettingsRepository(store)),
      act: (cubit) => cubit.select(ThemeMode.dark),
      expect: () => [ThemeMode.dark],
      verify: (_) =>
          expect(store.getString(SettingsRepository.themeModeKey), 'dark'),
    );
  });

  group('LocaleCubit', () {
    test('ignores stored locales that are no longer supported', () {
      final cubit = LocaleCubit(
        SettingsRepository(
          InMemoryKeyValueStore({SettingsRepository.localeKey: 'fr'}),
        ),
      );
      addTearDown(cubit.close);

      expect(cubit.state, isNull);
    });

    blocTest<LocaleCubit, Locale?>(
      'selects a locale and back to the device default',
      build: () => LocaleCubit(SettingsRepository(InMemoryKeyValueStore())),
      act: (cubit) async {
        await cubit.select(const Locale('es'));
        await cubit.select(null);
      },
      expect: () => [const Locale('es'), null],
    );
  });

  group('SettingsPage', () {
    late TestAppHarness harness;

    setUp(() => harness = TestAppHarness());

    ThemeMode appThemeMode(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

    testWidgets('switches and persists the theme mode', (tester) async {
      await harness.pump(tester, initialLocation: '/settings');

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(appThemeMode(tester), ThemeMode.dark);
      expect(
        harness.keyValueStore.getString(SettingsRepository.themeModeKey),
        'dark',
      );
    });

    testWidgets('switches the language', (tester) async {
      await harness.pump(tester, initialLocation: '/settings');

      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(find.text('Ajustes'), findsWidgets);
    });

    testWidgets('clears local data after confirmation', (tester) async {
      await harness.keyValueStore.setString(
        SettingsRepository.themeModeKey,
        'dark',
      );
      await harness.secureStore.write(SessionStore.accessTokenKey, 'token');
      await harness.database.postsDao.replaceAll([
        CachedPostsCompanion.insert(
          id: const Value(1),
          userId: 1,
          title: 't',
          body: 'b',
          cachedAt: DateTime.utc(2026),
        ),
      ]);
      await harness.pump(tester, initialLocation: '/settings');
      expect(appThemeMode(tester), ThemeMode.dark);

      await scrollToAndTap(tester, find.text('Clear local data'));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Local data cleared'), findsOneWidget);
      expect(appThemeMode(tester), ThemeMode.system);
      expect(harness.secureStore.values, isEmpty);
      expect(await harness.database.postsDao.getAll(), isEmpty);
    });
  });
}
