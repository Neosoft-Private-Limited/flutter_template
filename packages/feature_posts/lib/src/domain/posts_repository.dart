import 'package:core/core.dart';
import 'package:feature_posts/src/domain/post.dart';

/// Contract the presentation layer depends on. Tests substitute a fake.
abstract interface class PostsRepository {
  /// Latest posts, falling back to the last saved copy when offline.
  Future<Result<PostsFeed>> fetchPosts();

  /// One post, falling back to the saved copy when offline.
  Future<Result<Post>> fetchPost(int id);
}
