import 'dart:convert';

import 'package:app/features/posts/domain/post.dart';
import 'package:logging/logging.dart';
import 'package:networking/networking.dart';
import 'package:storage/storage.dart';

/// Keeps the last successful posts response for offline use.
///
/// Small payloads only: the key-value store loads everything into memory. For
/// large or relational data use a database (see docs/architecture.md).
final class PostsCache {
  const new(this._store);

  /// Bump the version when the cached shape changes; old entries are ignored.
  static const key = 'cache.posts.v1';
  static final Logger _log = Logger('PostsCache');

  final KeyValueStore _store;

  Future<void> save(List<Post> posts) => _store.setString(
    key,
    jsonEncode([for (final post in posts) post.toJson()]),
  );

  /// The cached posts, or `null` if nothing valid is cached.
  List<Post>? read() {
    final raw = _store.getString(key);
    if (raw == null) return null;
    try {
      return Json.list(jsonDecode(raw), Post.fromJson);
    } on FormatException catch (error) {
      _log.warning('Discarding corrupt posts cache', error);
      return null;
    }
  }
}
