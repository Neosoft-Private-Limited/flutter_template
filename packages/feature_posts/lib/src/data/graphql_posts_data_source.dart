import 'package:core/core.dart';
import 'package:feature_posts/src/data/posts_remote_data_source.dart';
import 'package:feature_posts/src/domain/post.dart';
import 'package:networking/networking.dart';

/// GraphQL version of the example API (GraphQLZero-compatible schema, which
/// mirrors JSONPlaceholder). Replace the documents with your schema's.
final class GraphQLPostsDataSource implements PostsRemoteDataSource {
  /// Creates a data source that sends its queries through the given client.
  const new(this._client, {this.pageSize = 100});

  final GraphQLClient _client;

  /// Maximum number of posts [fetchPosts] requests (first page only).
  final int pageSize;

  /// Query for the first page of posts, `pageSize` items long.
  static const postsQuery = r'''
query Posts($options: PageQueryOptions) {
  posts(options: $options) {
    data { id title body user { id } }
  }
}''';

  /// Query for a single post by id.
  static const postQuery = r'''
query Post($id: ID!) {
  post(id: $id) { id title body user { id } }
}''';

  @override
  Future<Result<List<Post>>> fetchPosts() => _client.query(
    postsQuery,
    operationName: 'Posts',
    variables: {
      'options': {
        'paginate': {'page': 1, 'limit': pageSize},
      },
    },
    decode: (data) => switch (data) {
      {'posts': {'data': final List<Object?> items}} => [
        for (final item in items) _decodePost(item),
      ],
      _ => throw FormatException('Unexpected posts payload', data),
    },
  );

  @override
  Future<Result<Post>> fetchPost(int id) async {
    final result = await _client.query(
      postQuery,
      operationName: 'Post',
      variables: {'id': '$id'},
      // The schema returns a post with null fields for unknown ids.
      decode: (data) => switch (data) {
        {'post': null} || {'post': {'id': null}} => null,
        {'post': final Object post} => _decodePost(post),
        _ => throw FormatException('Unexpected post payload', data),
      },
    );
    return switch (result) {
      Ok(value: final post?) => Ok(post),
      Ok(value: null) => Err(NotFoundFailure('GraphQL post $id not found')),
      Err(:final failure) => Err(failure),
    };
  }

  // GraphQL IDs are strings; the domain uses ints.
  static Post _decodePost(Object? json) => switch (json) {
    {
      'id': final String id,
      'title': final String title,
      'body': final String body,
      'user': {'id': final String userId},
    } =>
      Post(
        id: _parseId(id, json),
        userId: _parseId(userId, json),
        title: title,
        body: body,
      ),
    _ => throw FormatException('Invalid post payload', json),
  };

  static int _parseId(String raw, Object? source) =>
      int.tryParse(raw) ?? (throw FormatException('Invalid id "$raw"', source));
}
