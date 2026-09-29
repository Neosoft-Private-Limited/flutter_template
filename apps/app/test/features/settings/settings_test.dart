import 'package:app_foundation/app_foundation.dart';
import 'package:database/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:storage/storage.dart';

import '../../helpers/test_app.dart';

void main() {
  group('SettingsPage', () {
    late TestAppHarness harness;

    setUp(() => harness = TestAppHarness());

    ThemeMode appThemeMode(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

    testWidgets('switches and persists the theme mode', (tester) async {
      await harness.pump(tester, initialLocation: '/settings');
      expect(appThemeMode(tester), ThemeMode.system);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(appThemeMode(tester), ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.text('Settings').first)).brightness,
        Brightness.dark,
      );
      expect(
        harness.keyValueStore.getString(SettingsRepository.themeModeKey),
        'dark',
      );
    });

    testWidgets('restores the saved theme mode on start', (tester) async {
      await harness.keyValueStore.setString(
        SettingsRepository.themeModeKey,
        'light',
      );

      await harness.pump(tester, initialLocation: '/settings');

      expect(appThemeMode(tester), ThemeMode.light);
    });

    testWidgets('switches the language', (tester) async {
      await harness.pump(tester, initialLocation: '/settings');

      await tester.tap(find.text('Español'));
      await tester.pumpAndSettle();

      expect(find.text('Ajustes'), findsWidgets);
      expect(find.text('Inicio'), findsOneWidget);

      await tester.tap(find.text('Idioma del dispositivo'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('shows the build environment', (tester) async {
      await harness.pump(tester, initialLocation: '/settings');

      expect(find.text('dev'), findsOneWidget);
      expect(find.text('api.test.dev'), findsOneWidget);
    });

    testWidgets('clears local data after confirmation', (tester) async {
      await harness.keyValueStore.setString(
        SettingsRepository.themeModeKey,
        'dark',
      );
      await harness.database.postsDao.replaceAll([
        CachedPostsCompanion.insert(
          id: const Value(1),
          userId: 1,
          title: 't',
          body: 'b',
          cachedAt: DateTime.utc(2026),
        ),
      ]);
      await harness.keyValueStore.setInt(StorageMigrator.versionKey, 1);
      await harness.secureStore.write(SessionStore.accessTokenKey, 'token');
      await harness.pump(tester, initialLocation: '/settings');

      await scrollToAndTap(tester, find.text('Clear local data'));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Local data cleared'), findsOneWidget);
      expect(appThemeMode(tester), ThemeMode.system);
      expect(harness.keyValueStore.keys, {StorageMigrator.versionKey});
      expect(await harness.secureStore.read(SessionStore.accessTokenKey), null);
      expect(await harness.database.postsDao.getAll(), isEmpty);
    });

    testWidgets('keeps data when the dialog is cancelled', (tester) async {
      await harness.secureStore.write(SessionStore.accessTokenKey, 'token');
      await harness.pump(tester, initialLocation: '/settings');

      await scrollToAndTap(tester, find.text('Clear local data'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(
        await harness.secureStore.read(SessionStore.accessTokenKey),
        'token',
      );
    });
  });
}
