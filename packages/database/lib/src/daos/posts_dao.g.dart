// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts_dao.dart';

// ignore_for_file: type=lint
mixin _$PostsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedPostsTable get cachedPosts => attachedDatabase.cachedPosts;
  PostsDaoManager get managers => PostsDaoManager(this);
}

class PostsDaoManager {
  final _$PostsDaoMixin _db;
  PostsDaoManager(this._db);
  $$CachedPostsTableTableManager get cachedPosts =>
      $$CachedPostsTableTableManager(_db.attachedDatabase, _db.cachedPosts);
}
