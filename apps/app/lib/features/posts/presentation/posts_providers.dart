import 'package:app/app/di/providers.dart';
import 'package:app/features/posts/data/cached_posts_repository.dart';
import 'package:app/features/posts/data/posts_api.dart';
import 'package:app/features/posts/data/posts_cache.dart';
import 'package:app/features/posts/domain/post.dart';
import 'package:app/features/posts/domain/posts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;

final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => CachedPostsRepository(
    api: PostsApi(ref.watch(apiClientProvider)),
    cache: PostsCache(ref.watch(keyValueStoreProvider)),
  ),
);

/// The posts list. Failures surface as `AsyncError` carrying an `AppFailure`.
final postsControllerProvider =
    AsyncNotifierProvider<PostsController, PostsFeed>(
      PostsController.new,
      isAutoDispose: true,
    );

class PostsController extends AsyncNotifier<PostsFeed> {
  @override
  Future<PostsFeed> build() async =>
      (await ref.watch(postsRepositoryProvider).fetchPosts()).getOrThrow();

  /// Reloads while keeping the current list visible.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future.catchError((Object _) => const PostsFeed([]));
  }
}

/// A single post, loaded when the detail screen is opened.
final FutureProviderFamily<Post, int> postProvider = FutureProvider.family(
  (ref, id) async =>
      (await ref.watch(postsRepositoryProvider).fetchPost(id)).getOrThrow(),
  isAutoDispose: true,
);
