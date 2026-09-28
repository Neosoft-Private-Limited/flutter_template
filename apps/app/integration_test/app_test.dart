// End-to-end flows on a real device or simulator, with real storage and a
// fake HTTP transport (no network or credentials needed).
//
// Run with `melos run test:integration` (see docs/testing.md).
import 'package:app/app/app.dart';
import 'package:app/app/di/providers.dart';
import 'package:app/features/settings/data/settings_repository.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:networking/networking.dart';
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

  setUp(() async {
    keyValueStore = await SharedPreferencesKeyValueStore.create();
    await keyValueStore.clear();
  });

  Future<void> startApp(WidgetTester tester, FakeHttpAdapter adapter) async {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        retry: (_, _) => null,
        overrides: [
          appConfigProvider.overrideWithValue(config),
          keyValueStoreProvider.overrideWithValue(keyValueStore),
          secureStoreProvider.overrideWithValue(InMemorySecureStore()),
          apiClientProvider.overrideWithValue(
            ApiClient.create(
              baseUrl: config.apiBaseUrl,
              httpClientAdapter: adapter,
              maxRetries: 0,
            ),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('browse posts, open one, and read it offline later', (
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

    // Restart without network: the cached list is shown and flagged.
    await startApp(tester, FakeHttpAdapter.offline());
    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Showing saved posts'), findsOneWidget);
    expect(find.text('Post title 3'), findsOneWidget);
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
