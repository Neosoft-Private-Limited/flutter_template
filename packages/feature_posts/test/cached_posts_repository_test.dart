import 'package:core/core.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:networking/testing.dart';

void main() {
  final postJson = {'id': 1, 'userId': 7, 'title': 't', 'body': 'b'};

  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  PostsRepository repositoryWith(FakeHttpAdapter adapter) =>
      createPostsRepository(
        apiClient: ApiClient.create(
          baseUrl: Uri.parse('https://api.test.dev'),
          httpClientAdapter: adapter,
          maxRetries: 0,
        ),
        database: db,
      );

  Future<void> seedCache(List<Post> posts) =>
      PostsLocalDataSource(db.postsDao).saveAll(posts);

  test('returns fresh posts and stores them locally', () async {
    final adapter = FakeHttpAdapter.always(FakeResponse.json([postJson]));

    final result = await repositoryWith(adapter).fetchPosts();

    final feed = result.valueOrNull!;
    expect(feed.posts.single.userId, 7);
    expect(feed.isFromCache, isFalse);
    expect(adapter.requests.single.uri.path, '/posts');
    expect(await PostsLocalDataSource(db.postsDao).readAll(), feed.posts);
  });

  test('falls back to the local copy when offline', () async {
    await seedCache([Post.fromJson(postJson)]);

    final result = await repositoryWith(FakeHttpAdapter.offline()).fetchPosts();

    expect(result.valueOrNull!.isFromCache, isTrue);
    expect(result.valueOrNull!.posts.single.id, 1);
  });

  test('returns the failure when offline without a local copy', () async {
    final result = await repositoryWith(FakeHttpAdapter.offline()).fetchPosts();

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('does not hide non-transient failures behind the cache', () async {
    await seedCache([Post.fromJson(postJson)]);

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

  group('fetchPost', () {
    test('fetches one post by id', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse.json(postJson));

      final result = await repositoryWith(adapter).fetchPost(1);

      expect(result.valueOrNull!.title, 't');
      expect(adapter.requests.single.uri.path, '/posts/1');
    });

    test('uses the local copy when offline', () async {
      await seedCache([Post.fromJson(postJson)]);

      final result = await repositoryWith(FakeHttpAdapter.offline())
          .fetchPost(1);

      expect(result.valueOrNull!.id, 1);
    });

    test('reports not found', () async {
      final result = await repositoryWith(
        FakeHttpAdapter.always(const FakeResponse(404)),
      ).fetchPost(99);

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  test('PostsFeed has value equality', () {
    final post = Post.fromJson(postJson);

    expect(PostsFeed([post]), PostsFeed([post]));
    expect(PostsFeed([post]), isNot(PostsFeed([post], isFromCache: true)));
    expect(PostsFeed([post]).hashCode, PostsFeed([post]).hashCode);
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
