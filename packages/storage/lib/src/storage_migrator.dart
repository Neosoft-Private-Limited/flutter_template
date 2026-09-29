import 'package:core/core.dart';
import 'package:logging/logging.dart';
import 'package:storage/src/key_value_store.dart';
import 'package:storage/src/secure_store.dart';

/// One step that upgrades persisted data from `version - 1` to [version].
final class StorageMigration {
  /// Creates the step that brings data to [version] by running [migrate].
  const new({
    required this.version,
    required this.description,
    required this.migrate,
  });

  /// The schema version this step produces; unique and `>= 1`.
  final int version;

  /// A short summary of the change, written to the log when the step runs.
  final String description;

  /// Performs the upgrade. It must be idempotent, because it runs again if
  /// the app is killed before the new version is saved. Throw an [Exception]
  /// to abort; `StorageMigrator.run` then returns a [StorageFailure].
  final Future<void> Function(KeyValueStore store, SecureStore secureStore)
  migrate;
}

/// Brings persisted data up to date at start-up.
///
/// The current schema version is stored under [versionKey]. Migrations run in
/// ascending order and the version is saved after each successful step, so an
/// interrupted upgrade resumes where it stopped. Migrations must therefore be
/// idempotent.
final class StorageMigrator {
  /// Creates a migrator for [store] and [secureStore].
  ///
  /// [migrations] may be given in any order; they are sorted by version.
  /// Throws an [ArgumentError] if two share a version or any version is
  /// below 1.
  new({
    required this.store,
    required this.secureStore,
    required List<StorageMigration> migrations,
  }) : migrations = List<StorageMigration>.unmodifiable(
         migrations.toList()..sort((a, b) => a.version.compareTo(b.version)),
       ) {
    final versions = this.migrations.map((m) => m.version).toList();
    if (versions.toSet().length != versions.length ||
        versions.any((v) => v < 1)) {
      throw ArgumentError.value(
        versions,
        'migrations',
        'Versions must be unique and >= 1',
      );
    }
  }

  /// The [KeyValueStore] key holding the last applied schema version.
  static const versionKey = 'storage.schema_version';

  /// The [KeyValueStore] key set on first launch. When it is missing, [run]
  /// wipes [secureStore], because iOS keeps Keychain items after an
  /// uninstall while preferences are deleted.
  static const installMarkerKey = 'storage.install_marker';
  static final Logger _log = Logger('StorageMigrator');

  /// The store that holds the schema version and non-sensitive data.
  final KeyValueStore store;

  /// The secret store passed to each migration.
  final SecureStore secureStore;

  /// All migrations, sorted by ascending version; unmodifiable.
  final List<StorageMigration> migrations;

  /// The schema version of the persisted data; `0` before any migration.
  int get currentVersion => store.getInt(versionKey) ?? 0;

  /// The version [run] upgrades to: the highest migration version, or `0`
  /// when there are no migrations.
  int get targetVersion => migrations.isEmpty ? 0 : migrations.last.version;

  /// Runs pending migrations. Returns a [StorageFailure] if one fails; data
  /// migrated by earlier steps is kept.
  Future<Result<int>> run() async {
    await _clearSecretsAfterReinstall();

    final pending = migrations.where((m) => m.version > currentVersion);
    for (final migration in pending) {
      _log.info(
        'Migrating storage to v${migration.version}: '
        '${migration.description}',
      );
      try {
        await migration.migrate(store, secureStore);
        await store.setInt(versionKey, migration.version);
      } on Exception catch (error, stackTrace) {
        return Err(
          StorageFailure(
            'Storage migration to v${migration.version} failed',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
    }
    return Ok(currentVersion);
  }

  // iOS keeps Keychain items after an app is uninstalled while preferences are
  // deleted. A missing marker therefore means a fresh install: drop secrets
  // left behind by a previous installation (for example an old session).
  Future<void> _clearSecretsAfterReinstall() async {
    if (store.getBool(installMarkerKey) ?? false) return;
    await secureStore.deleteAll();
    await store.setBool(installMarkerKey, value: true);
  }
}
