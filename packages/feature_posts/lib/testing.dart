/// Test doubles for code that uses the posts feature. Import only from tests.
library;

import 'package:core/core.dart';
import 'package:feature_posts/src/domain/post.dart';
import 'package:feature_posts/src/domain/posts_repository.dart';

/// A post with predictable fields: `Title <id>`, `Body <id>`.
Post testPost(int id) =>
    Post(id: id, userId: 1, title: 'Title $id', body: 'Body $id');

/// A controllable [PostsRepository]. Assign [onFetchPosts] or [onFetchPost]
/// to change responses; return a `Completer` future to hold the loading
/// state.
final class FakePostsRepository implements PostsRepository {
  /// Answers [fetchPosts]. Defaults to a feed of posts 1 and 2.
  Future<Result<PostsFeed>> Function() onFetchPosts = () async =>
      Ok(PostsFeed([testPost(1), testPost(2)]));

  /// Answers [fetchPost]. Defaults to [testPost] for the requested id.
  Future<Result<Post>> Function(int id) onFetchPost = (id) async =>
      Ok(testPost(id));

  /// How many times [fetchPosts] was called.
  int fetchPostsCalls = 0;

  @override
  Future<Result<PostsFeed>> fetchPosts() {
    fetchPostsCalls++;
    return onFetchPosts();
  }

  @override
  Future<Result<Post>> fetchPost(int id) => onFetchPost(id);
}
