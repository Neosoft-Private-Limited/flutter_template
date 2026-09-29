import 'package:app/app/base/view_model.dart';
import 'package:app/app/di/providers.dart';
import 'package:core/core.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show AsyncNotifierProviderFamily;

// Model: the repository. View models: below. Views: PostsPage and
// PostDetailPage.

final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => createPostsRepository(
    apiClient: ref.watch(apiClientProvider),
    graphQLClient: ref.watch(graphQLClientProvider),
    database: ref.watch(databaseProvider),
  ),
);

/// View model of the posts list.
class PostsViewModel extends AsyncViewModel<PostsFeed> {
  @override
  Future<Result<PostsFeed>> load() =>
      ref.watch(postsRepositoryProvider).fetchPosts();
}

final postsViewModelProvider = AsyncNotifierProvider<PostsViewModel, PostsFeed>(
  PostsViewModel.new,
  isAutoDispose: true,
);

/// View model of one post. The family argument is the post id.
class PostDetailViewModel extends AsyncViewModel<Post> {
  new(this.postId);

  final int postId;

  @override
  Future<Result<Post>> load() =>
      ref.watch(postsRepositoryProvider).fetchPost(postId);
}

final AsyncNotifierProviderFamily<PostDetailViewModel, Post, int>
postDetailViewModelProvider = AsyncNotifierProvider.family(
  PostDetailViewModel.new,
  isAutoDispose: true,
);
