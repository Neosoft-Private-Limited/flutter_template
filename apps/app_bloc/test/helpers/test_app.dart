import 'package:app_bloc/app/app.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:core/core.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:feature_posts/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:storage/storage.dart';

export 'package:feature_posts/testing.dart';

final testConfig = AppConfig.fromMap(const {
  ConfigKeys.environment: 'dev',
  ConfigKeys.apiBaseUrl: 'https://api.test.dev',
});

/// Everything a widget test needs to start the real [App] without I/O.
final class TestAppHarness {
  new()
    : keyValueStore = InMemoryKeyValueStore(),
      secureStore = InMemorySecureStore(),
      postsRepository = FakePostsRepository(),
      database = AppDatabase(NativeDatabase.memory()) {
    addTearDown(database.close);
  }

  final InMemoryKeyValueStore keyValueStore;
  final InMemorySecureStore secureStore;
  final FakePostsRepository postsRepository;

  /// In-memory SQLite database (real drift, no files).
  final AppDatabase database;

  Future<void> pump(
    WidgetTester tester, {
    String initialLocation = '/home',
    Size size = const Size(400, 800),
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        config: testConfig,
        postsRepository: postsRepository,
        settingsRepository: SettingsRepository(keyValueStore),
        localDataCleaner: LocalDataCleaner(
          keyValueStore: keyValueStore,
          secureStore: secureStore,
          database: database,
        ),
        initialLocation: initialLocation,
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }
}

/// Scrolls [finder] to the top of the viewport and taps it.
Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
