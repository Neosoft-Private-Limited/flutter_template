import 'package:app/features/posts/domain/post.dart';
import 'package:core/core.dart';

/// Contract the presentation layer depends on. Tests substitute a fake.
abstract interface class PostsRepository {
  /// Latest posts from the API, falling back to the last saved copy when the
  /// device is offline.
  Future<Result<PostsFeed>> fetchPosts();

  Future<Result<Post>> fetchPost(int id);
}
