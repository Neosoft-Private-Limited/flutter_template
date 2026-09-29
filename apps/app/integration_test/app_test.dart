// End-to-end flows on a real device or simulator, with real storage (shared
// preferences and an on-device SQLite database) and a fake HTTP transport
// (no network or credentials needed).
//
// Run with `melos run test:integration` (see docs/testing.md).
import 'package:app/app/app.dart';
import 'package:app/app/di/providers.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:core/core.dart';
import 'package:database/database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:networking/testing.dart';
import 'package:storage/storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromMap(const {
    ConfigKeys.environment: 'dev',
    ConfigKeys.apiBaseUrl: 'https://api.integration.test',
  });

  final postsJson = [
    for (var id = 1; id <= 3; id++)
      {'id': id, 'userId': 1, 'title': 'Post title $id', 'body': 'Body $id'},
  ];

  late SharedPreferencesKeyValueStore keyValueStore;
  late AppDatabase database;

  setUp(() async {
    keyValueStore = await SharedPreferencesKeyValueStore.create();
    await keyValueStore.clear();
    database = AppDatabase.open(name: 'integration_test');
    await database.clearAll();
  });

  tearDown(() => database.close());

  /// Starts (or restarts) the app with fresh services on the same storage.
  Future<void> startApp(WidgetTester tester, FakeHttpAdapter adapter) async {
    final services = AppServices.fromStores(
      config: config,
      keyValueStore: keyValueStore,
      secureStore: InMemorySecureStore(),
      database: database,
      errorReporter: LoggingErrorReporter(),
      httpClientAdapter: adapter,
    );
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        retry: (_, _) => null,
        overrides: overridesFor(services),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('browse posts, open one, and read them offline later', (
    tester,
  ) async {
    final online = FakeHttpAdapter((request, _) async {
      final path = request.uri.path;
      if (path == '/posts') return FakeResponse.json(postsJson);
      if (path == '/posts/2') return FakeResponse.json(postsJson[1]);
      return const FakeResponse(404);
    });
    await startApp(tester, online);

    expect(find.text('Components'), findsWidgets);
    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();
    expect(find.text('Post title 1'), findsOneWidget);

    await tester.tap(find.text('Post title 2'));
    await tester.pumpAndSettle();
    expect(find.text('Body 2'), findsOneWidget);

    // Restart without network: the list comes from the SQLite cache.
    await startApp(tester, FakeHttpAdapter.offline());
    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Showing saved posts'), findsOneWidget);
    expect(find.text('Post title 3'), findsOneWidget);

    // A cached post also opens offline.
    await tester.tap(find.text('Post title 3'));
    await tester.pumpAndSettle();
    expect(find.text('Body 3'), findsOneWidget);
  });

  testWidgets('theme and language choices survive a restart', (tester) async {
    final adapter = FakeHttpAdapter.always(FakeResponse.json(postsJson));
    await startApp(tester, adapter);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();

    await startApp(tester, adapter);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(find.text('Componentes'), findsWidgets);
    expect(keyValueStore.getString(SettingsRepository.themeModeKey), 'dark');
  });
}
