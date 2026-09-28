import 'package:app/features/posts/domain/post.dart';
import 'package:core/core.dart';
import 'package:networking/networking.dart';

/// Typed endpoints of the example API (JSONPlaceholder-compatible).
final class PostsApi {
  const new(this._client);

  final ApiClient _client;

  Future<Result<List<Post>>> getPosts({CancelToken? cancelToken}) =>
      _client.get(
        'posts',
        decode: (json) => Json.list(json, Post.fromJson),
        cancelToken: cancelToken,
      );

  Future<Result<Post>> getPost(int id, {CancelToken? cancelToken}) =>
      _client.get('posts/$id', decode: Post.fromJson, cancelToken: cancelToken);
}
