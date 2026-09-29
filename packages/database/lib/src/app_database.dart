import 'package:database/src/daos/posts_dao.dart';
import 'package:database/src/tables/cached_posts.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// The app's SQLite database.
///
/// Schema changes: bump [schemaVersion], run
/// `dart run drift_dev make-migrations` in this package, and add the step to
/// [migration]. See packages/database/README.md.
@DriftDatabase(tables: [CachedPosts], daos: [PostsDao])
class AppDatabase extends _$AppDatabase {
  /// Opens the database on the query executor [e]. Tests pass
  /// `NativeDatabase.memory()`.
  new(super.e);

  /// Opens the on-device database: a file in the app documents directory on
  /// mobile and desktop, IndexedDB/OPFS on the web (requires `sqlite3.wasm`
  /// and `drift_worker.js` in the app's `web/` folder).
  factory open({String name = 'app'}) => AppDatabase(
    driftDatabase(
      name: name,
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // No upgrades yet. When you bump schemaVersion, generate step helpers
    // with `make-migrations` and handle each version here, for example:
    //   onUpgrade: stepByStep(from1To2: (m, schema) async {
    //     await m.addColumn(schema.cachedPosts, schema.cachedPosts.isRead);
    //   }),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Deletes every row in every table (used when clearing local data).
  Future<void> clearAll() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });
}
