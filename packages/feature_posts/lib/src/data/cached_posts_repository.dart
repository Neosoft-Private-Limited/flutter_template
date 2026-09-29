import 'package:core/core.dart';
import 'package:feature_posts/src/data/posts_local_data_source.dart';
import 'package:feature_posts/src/data/posts_remote_data_source.dart';
import 'package:feature_posts/src/domain/post.dart';
import 'package:feature_posts/src/domain/posts_repository.dart';
import 'package:logging/logging.dart';

/// Network-first repository with an offline fallback.
///
/// Successful list responses refresh the local copy. When a request fails
/// with a transient failure (offline, timeout, 5xx) and a local copy exists,
/// the local copy is returned (flagged for lists). Other failures (401, 404,
/// bad payload) are returned as-is.
final class CachedPostsRepository implements PostsRepository {
  /// Creates a repository that fetches from the remote data source and
  /// falls back to the local one.
  const new({required this._remote, required this._local});

  final PostsRemoteDataSource _remote;
  final PostsLocalDataSource _local;
  static final Logger _log = Logger('CachedPostsRepository');

  @override
  Future<Result<PostsFeed>> fetchPosts() async {
    switch (await _remote.fetchPosts()) {
      case Ok(:final value):
        await _guard(() => _local.saveAll(value));
        return Ok(PostsFeed(value));
      case Err(:final failure) when failure.isTransient:
        final cached = await _guard(_local.readAll) ?? const [];
        return cached.isEmpty
            ? Err(failure)
            : Ok(PostsFeed(cached, isFromCache: true));
      case Err(:final failure):
        return Err(failure);
    }
  }

  @override
  Future<Result<Post>> fetchPost(int id) async {
    switch (await _remote.fetchPost(id)) {
      case Ok(:final value):
        return Ok(value);
      case Err(:final failure) when failure.isTransient:
        final cached = await _guard(() => _local.read(id));
        return cached == null ? Err(failure) : Ok(cached);
      case Err(:final failure):
        return Err(failure);
    }
  }

  // A broken cache must never hide the network result: log and carry on.
  Future<T?> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on Exception catch (error, stackTrace) {
      _log.warning('Posts cache operation failed', error, stackTrace);
      return null;
    }
  }
}
