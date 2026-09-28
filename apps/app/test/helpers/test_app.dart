import 'dart:async';

import 'package:app/app/app.dart';
import 'package:app/app/di/providers.dart';
import 'package:app/app/router/app_router.dart';
import 'package:app/features/posts/domain/post.dart';
import 'package:app/features/posts/domain/posts_repository.dart';
import 'package:app/features/posts/presentation/posts_providers.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:storage/storage.dart';

final testConfig = AppConfig.fromMap(const {
  ConfigKeys.environment: 'dev',
  ConfigKeys.apiBaseUrl: 'https://api.test.dev',
});

Post testPost(int id) =>
    Post(id: id, userId: 1, title: 'Title $id', body: 'Body $id');

/// A controllable [PostsRepository]. Assign [onFetchPosts] to change the
/// response; use a [Completer] to hold the loading state.
final class FakePostsRepository implements PostsRepository {
  Future<Result<PostsFeed>> Function() onFetchPosts = () async =>
      Ok(PostsFeed([testPost(1), testPost(2)]));
  Future<Result<Post>> Function(int id) onFetchPost = (id) async =>
      Ok(testPost(id));

  int fetchPostsCalls = 0;

  @override
  Future<Result<PostsFeed>> fetchPosts() {
    fetchPostsCalls++;
    return onFetchPosts();
  }

  @override
  Future<Result<Post>> fetchPost(int id) => onFetchPost(id);
}

/// Everything a widget test needs to start the real [App] without I/O.
final class TestAppHarness {
  new({
    KeyValueStore? keyValueStore,
    SecureStore? secureStore,
    FakePostsRepository? postsRepository,
  }) : keyValueStore = keyValueStore ?? InMemoryKeyValueStore(),
       secureStore = secureStore ?? InMemorySecureStore(),
       postsRepository = postsRepository ?? FakePostsRepository();

  final KeyValueStore keyValueStore;
  final SecureStore secureStore;
  final FakePostsRepository postsRepository;

  List<Override> overrides({String initialLocation = '/home'}) => [
    appConfigProvider.overrideWithValue(testConfig),
    keyValueStoreProvider.overrideWithValue(keyValueStore),
    secureStoreProvider.overrideWithValue(secureStore),
    postsRepositoryProvider.overrideWithValue(postsRepository),
    routerProvider.overrideWith((ref) {
      final router = createRouter(initialLocation: initialLocation);
      ref.onDispose(router.dispose);
      return router;
    }),
  ];

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
      ProviderScope(
        retry: (_, _) => null,
        overrides: overrides(initialLocation: initialLocation),
        child: const App(),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }
}

/// Scrolls [finder] into view (to the top of the viewport, clear of the
/// bottom navigation bar) and taps it.
Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
