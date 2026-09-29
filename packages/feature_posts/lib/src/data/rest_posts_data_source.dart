import 'package:core/core.dart';
import 'package:feature_posts/src/data/posts_remote_data_source.dart';
import 'package:feature_posts/src/domain/post.dart';
import 'package:networking/networking.dart';

/// REST endpoints of the example API (JSONPlaceholder-compatible):
/// `GET posts` and `GET posts/{id}`.
final class RestPostsDataSource implements PostsRemoteDataSource {
  /// Creates a data source that sends its requests through the given client.
  const new(this._client);

  final ApiClient _client;

  @override
  Future<Result<List<Post>>> fetchPosts() =>
      _client.get('posts', decode: (json) => Json.list(json, Post.fromJson));

  @override
  Future<Result<Post>> fetchPost(int id) =>
      _client.get('posts/$id', decode: Post.fromJson);
}
