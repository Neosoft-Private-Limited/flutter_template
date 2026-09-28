import 'package:app/features/posts/data/posts_api.dart';
import 'package:app/features/posts/data/posts_cache.dart';
import 'package:app/features/posts/domain/post.dart';
import 'package:app/features/posts/domain/posts_repository.dart';
import 'package:core/core.dart';

/// Network-first repository with an offline fallback.
///
/// Successful responses refresh the cache. When the request fails with a
/// transient failure (offline, timeout, 5xx) and a cached copy exists, the
/// cached copy is returned and flagged, so the UI can say so. Other failures
/// (401, 404, bad payload) are returned as-is.
final class CachedPostsRepository implements PostsRepository {
  const new({required this._api, required this._cache});

  final PostsApi _api;
  final PostsCache _cache;

  @override
  Future<Result<PostsFeed>> fetchPosts() async {
    switch (await _api.getPosts()) {
      case Ok(:final value):
        await _cache.save(value);
        return Ok(PostsFeed(value));
      case Err(:final failure) when failure.isTransient:
        final cached = _cache.read();
        return cached == null
            ? Err(failure)
            : Ok(PostsFeed(cached, isFromCache: true));
      case Err(:final failure):
        return Err(failure);
    }
  }

  @override
  Future<Result<Post>> fetchPost(int id) => _api.getPost(id);
}
