import 'package:database/database.dart';
import 'package:feature_posts/src/domain/post.dart';

/// Offline copy of the posts, stored in the drift database.
final class PostsLocalDataSource {
  /// Creates a data source over the given DAO. [clock] stamps saved rows
  /// and defaults to [DateTime.now]; pass a fixed one in tests.
  new(this._dao, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final PostsDao _dao;
  final DateTime Function() _clock;

  /// Replaces the whole offline copy with [posts]; posts missing from the
  /// list are removed.
  Future<void> saveAll(List<Post> posts) {
    final now = _clock().toUtc();
    return _dao.replaceAll([
      for (final post in posts)
        CachedPostsCompanion.insert(
          id: Value(post.id),
          userId: post.userId,
          title: post.title,
          body: post.body,
          cachedAt: now,
        ),
    ]);
  }

  /// Every saved post, ordered by id; empty when nothing is saved.
  Future<List<Post>> readAll() async => [
    for (final row in await _dao.getAll()) _toPost(row),
  ];

  /// The saved post with [id], or `null` when it is not saved.
  Future<Post?> read(int id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toPost(row);
  }

  static Post _toPost(CachedPostRow row) =>
      Post(id: row.id, userId: row.userId, title: row.title, body: row.body);
}
