import 'package:core/core.dart';
import 'package:feature_posts/src/domain/post.dart';

/// Where posts come from over the network. Implemented for REST and GraphQL;
/// the repository does not know which transport is used.
abstract interface class PostsRemoteDataSource {
  /// The latest posts, or the failure that prevented loading them.
  Future<Result<List<Post>>> fetchPosts();

  /// The post with [id]; fails with `NotFoundFailure` when it does not
  /// exist.
  Future<Result<Post>> fetchPost(int id);
}
