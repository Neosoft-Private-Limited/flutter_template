import 'package:core/core.dart';
import 'package:logging/logging.dart';
import 'package:storage/src/key_value_store.dart';
import 'package:storage/src/secure_store.dart';

/// One step that upgrades persisted data from `version - 1` to [version].
final class StorageMigration {
  const new({
    required this.version,
    required this.description,
    required this.migrate,
  });

  final int version;
  final String description;
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

  static const versionKey = 'storage.schema_version';
  static const installMarkerKey = 'storage.install_marker';
  static final Logger _log = Logger('StorageMigrator');

  final KeyValueStore store;
  final SecureStore secureStore;
  final List<StorageMigration> migrations;

  int get currentVersion => store.getInt(versionKey) ?? 0;
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
