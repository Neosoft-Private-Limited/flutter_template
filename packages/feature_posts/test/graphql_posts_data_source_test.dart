import 'package:core/core.dart';
import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:networking/networking.dart';
import 'package:networking/testing.dart';

void main() {
  final endpoint = Uri.parse('https://gql.test.dev/api');

  Map<String, Object?> gqlPost(String id) => {
    'id': id,
    'title': 'Title $id',
    'body': 'Body $id',
    'user': {'id': '3'},
  };

  GraphQLPostsDataSource sourceWith(FakeHttpAdapter adapter) =>
      GraphQLPostsDataSource(
        GraphQLClient.create(
          endpoint: endpoint,
          settings: HttpSettings(httpClientAdapter: adapter, maxRetries: 0),
        ),
      );

  test('decodes the posts query and converts string ids', () async {
    final adapter = FakeHttpAdapter.always(
      FakeResponse.json({
        'data': {
          'posts': {
            'data': [gqlPost('1'), gqlPost('2')],
          },
        },
      }),
    );

    final result = await sourceWith(adapter).fetchPosts();

    expect(result.valueOrNull!.map((p) => (p.id, p.userId)), [(1, 3), (2, 3)]);
    expect(adapter.requests.single.uri, endpoint);
  });

  test('decodes a single post', () async {
    final result = await sourceWith(
      FakeHttpAdapter.always(
        FakeResponse.json({
          'data': {'post': gqlPost('5')},
        }),
      ),
    ).fetchPost(5);

    expect(result.valueOrNull!.title, 'Title 5');
  });

  test('maps a post with null fields to NotFoundFailure', () async {
    final result = await sourceWith(
      FakeHttpAdapter.always(
        FakeResponse.json({
          'data': {
            'post': {'id': null, 'title': null, 'body': null, 'user': null},
          },
        }),
      ),
    ).fetchPost(999);

    expect(result.failureOrNull, isA<NotFoundFailure>());
  });

  test('rejects non-numeric ids', () async {
    final result = await sourceWith(
      FakeHttpAdapter.always(
        FakeResponse.json({
          'data': {'post': gqlPost('abc')},
        }),
      ),
    ).fetchPost(1);

    expect(result.failureOrNull, isA<ParsingFailure>());
  });

  test('createPostsRepository uses GraphQL when a client is given', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final restAdapter = FakeHttpAdapter.always(const FakeResponse(500));
    final gqlAdapter = FakeHttpAdapter.always(
      FakeResponse.json({
        'data': {
          'posts': {
            'data': [gqlPost('1')],
          },
        },
      }),
    );

    final repository = createPostsRepository(
      apiClient: ApiClient.create(
        baseUrl: Uri.parse('https://api.test.dev'),
        httpClientAdapter: restAdapter,
      ),
      graphQLClient: GraphQLClient.create(
        endpoint: endpoint,
        settings: HttpSettings(httpClientAdapter: gqlAdapter),
      ),
      database: db,
    );

    final result = await repository.fetchPosts();

    expect(result.valueOrNull!.posts.single.id, 1);
    expect(restAdapter.requests, isEmpty);
  });
}
