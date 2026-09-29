import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

void main() {
  late InMemoryKeyValueStore store;
  late InMemorySecureStore secureStore;

  setUp(() {
    store = InMemoryKeyValueStore({StorageMigrator.installMarkerKey: true});
    secureStore = InMemorySecureStore();
  });

  StorageMigration migration(int version, List<int> log) => StorageMigration(
    version: version,
    description: 'step $version',
    migrate: (_, _) async => log.add(version),
  );

  test('runs pending migrations in ascending order', () async {
    final log = <int>[];
    final migrator = StorageMigrator(
      store: store,
      secureStore: secureStore,
      migrations: [migration(2, log), migration(1, log), migration(3, log)],
    );

    final result = await migrator.run();

    expect(log, [1, 2, 3]);
    expect(result, const Ok(3));
    expect(store.getInt(StorageMigrator.versionKey), 3);
  });

  test('skips migrations that already ran', () async {
    await store.setInt(StorageMigrator.versionKey, 2);
    final log = <int>[];

    await StorageMigrator(
      store: store,
      secureStore: secureStore,
      migrations: [migration(1, log), migration(2, log), migration(3, log)],
    ).run();

    expect(log, [3]);
  });

  test('stops at the failing step and keeps earlier progress', () async {
    final log = <int>[];
    final migrator = StorageMigrator(
      store: store,
      secureStore: secureStore,
      migrations: [
        migration(1, log),
        StorageMigration(
          version: 2,
          description: 'broken',
          migrate: (_, _) async => throw const FormatException('bad data'),
        ),
        migration(3, log),
      ],
    );

    final result = await migrator.run();

    expect(result.failureOrNull, isA<StorageFailure>());
    expect(log, [1]);
    expect(migrator.currentVersion, 1);
  });

  test('migrations can move data between stores', () async {
    await store.setString('legacy_token', 'abc');

    await StorageMigrator(
      store: store,
      secureStore: secureStore,
      migrations: [
        StorageMigration(
          version: 1,
          description: 'move token to secure storage',
          migrate: (kv, secure) async {
            final token = kv.getString('legacy_token');
            if (token != null) await secure.write('access_token', token);
            await kv.remove('legacy_token');
          },
        ),
      ],
    ).run();

    expect(store.containsKey('legacy_token'), isFalse);
    expect(secureStore.values, {'access_token': 'abc'});
  });

  test('clears secrets left over from a previous installation', () async {
    final freshStore = InMemoryKeyValueStore();
    final leftover = InMemorySecureStore({'access_token': 'old'});

    await StorageMigrator(
      store: freshStore,
      secureStore: leftover,
      migrations: const [],
    ).run();
    await leftover.write('access_token', 'new');
    await StorageMigrator(
      store: freshStore,
      secureStore: leftover,
      migrations: const [],
    ).run();

    expect(leftover.values, {'access_token': 'new'});
  });

  test('rejects duplicate or non-positive versions', () {
    expect(
      () => StorageMigrator(
        store: store,
        secureStore: secureStore,
        migrations: [migration(1, []), migration(1, [])],
      ),
      throwsArgumentError,
    );
    expect(
      () => StorageMigrator(
        store: store,
        secureStore: secureStore,
        migrations: [migration(0, [])],
      ),
      throwsArgumentError,
    );
  });
}
