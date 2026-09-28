import 'package:app/features/posts/data/cached_posts_repository.dart';
import 'package:app/features/posts/data/posts_api.dart';
import 'package:app/features/posts/data/posts_cache.dart';
import 'package:app/features/posts/domain/post.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:networking/testing.dart';
import 'package:storage/storage.dart';

void main() {
  final postJson = {'id': 1, 'userId': 7, 'title': 't', 'body': 'b'};

  late InMemoryKeyValueStore store;

  setUp(() => store = InMemoryKeyValueStore());

  CachedPostsRepository repositoryWith(FakeHttpAdapter adapter) =>
      CachedPostsRepository(
        api: PostsApi(
          ApiClient.create(
            baseUrl: Uri.parse('https://api.test.dev/'),
            httpClientAdapter: adapter,
            maxRetries: 0,
          ),
        ),
        cache: PostsCache(store),
      );

  test('returns fresh posts and saves them to the cache', () async {
    final adapter = FakeHttpAdapter.always(FakeResponse.json([postJson]));

    final result = await repositoryWith(adapter).fetchPosts();

    final feed = result.valueOrNull!;
    expect(feed.posts.single.userId, 7);
    expect(feed.isFromCache, isFalse);
    expect(adapter.requests.single.uri.path, '/posts');
    expect(PostsCache(store).read(), feed.posts);
  });

  test('falls back to cached posts when offline', () async {
    await PostsCache(store).save([Post.fromJson(postJson)]);

    final result = await repositoryWith(FakeHttpAdapter.offline()).fetchPosts();

    expect(result.valueOrNull!.isFromCache, isTrue);
    expect(result.valueOrNull!.posts.single.id, 1);
  });

  test('returns the failure when offline without a cache', () async {
    final result = await repositoryWith(FakeHttpAdapter.offline()).fetchPosts();

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('does not hide non-transient failures behind the cache', () async {
    await PostsCache(store).save([Post.fromJson(postJson)]);

    final result = await repositoryWith(
      FakeHttpAdapter.always(const FakeResponse(401)),
    ).fetchPosts();

    expect(result.failureOrNull, isA<UnauthorizedFailure>());
  });

  test('rejects malformed payloads', () async {
    final result = await repositoryWith(
      FakeHttpAdapter.always(
        FakeResponse.json([
          {'id': '1'},
        ]),
      ),
    ).fetchPosts();

    expect(result.failureOrNull, isA<ParsingFailure>());
  });

  test('fetches a single post by id', () async {
    final adapter = FakeHttpAdapter.always(FakeResponse.json(postJson));

    final result = await repositoryWith(adapter).fetchPost(1);

    expect(result.valueOrNull!.title, 't');
    expect(adapter.requests.single.uri.path, '/posts/1');
  });

  group('PostsCache', () {
    test('ignores corrupt entries', () async {
      await store.setString(PostsCache.key, '{not json');

      expect(PostsCache(store).read(), isNull);
    });

    test('returns null when empty', () {
      expect(PostsCache(store).read(), isNull);
    });
  });

  group('Post.fromJson', () {
    test('round-trips through toJson', () {
      final post = Post.fromJson(postJson);

      expect(Post.fromJson(post.toJson()), post);
    });

    test('rejects missing or mistyped fields', () {
      for (final json in <Object?>[
        null,
        [],
        {'id': 1},
        {...postJson, 'id': '1'},
      ]) {
        expect(
          () => Post.fromJson(json),
          throwsFormatException,
          reason: '$json',
        );
      }
    });
  });
}
