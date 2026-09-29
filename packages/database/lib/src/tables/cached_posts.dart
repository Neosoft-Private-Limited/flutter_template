import 'package:drift/drift.dart';

/// Offline copy of the posts list from the example API.
@DataClassName('CachedPostRow')
class CachedPosts extends Table {
  /// The post id assigned by the API; the primary key.
  IntColumn get id => integer()();

  /// The id of the user who wrote the post.
  IntColumn get userId => integer()();

  /// The post title as returned by the API.
  TextColumn get title => text()();

  /// The full post text as returned by the API.
  TextColumn get body => text()();

  /// When the row was last refreshed from the network.
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
