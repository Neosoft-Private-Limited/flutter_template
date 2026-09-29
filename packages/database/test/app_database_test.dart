import 'package:database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  CachedPostsCompanion row(int id, {String title = 'Title'}) =>
      CachedPostsCompanion.insert(
        id: Value(id),
        userId: 1,
        title: '$title $id',
        body: 'Body $id',
        cachedAt: DateTime.utc(2026, 9, 28),
      );

  group('PostsDao', () {
    test('replaceAll stores rows ordered by id', () async {
      await db.postsDao.replaceAll([row(2), row(1)]);

      final rows = await db.postsDao.getAll();

      expect(rows.map((r) => r.id), [1, 2]);
      expect(rows.first.title, 'Title 1');
      expect(rows.first.cachedAt, DateTime.utc(2026, 9, 28));
    });

    test('replaceAll removes rows that are no longer present', () async {
      await db.postsDao.replaceAll([row(1), row(2), row(3)]);
      await db.postsDao.replaceAll([row(3, title: 'New')]);

      final rows = await db.postsDao.getAll();

      expect(rows.single.title, 'New 3');
    });

    test('getById returns a row or null', () async {
      await db.postsDao.replaceAll([row(7)]);

      expect((await db.postsDao.getById(7))?.body, 'Body 7');
      expect(await db.postsDao.getById(8), isNull);
    });

    test('watchAll emits when the table changes', () async {
      final emissions = db.postsDao.watchAll().map((r) => r.length);

      final expectation = expectLater(emissions, emitsInOrder([0, 2]));
      await Future<void>.delayed(Duration.zero);
      await db.postsDao.replaceAll([row(1), row(2)]);

      await expectation;
    });
  });

  test('clearAll empties every table', () async {
    await db.postsDao.replaceAll([row(1)]);

    await db.clearAll();

    expect(await db.postsDao.getAll(), isEmpty);
  });

  test('schema version matches the latest schema snapshot', () {
    // Bump together with drift_schemas/ (dart run drift_dev make-migrations).
    expect(db.schemaVersion, 1);
  });
}
