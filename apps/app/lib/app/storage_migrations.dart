import 'package:storage/storage.dart';

/// Ordered storage migrations, run by `bootstrap` before the UI starts.
///
/// Append a new [StorageMigration] with the next version whenever the shape
/// or location of persisted data changes. Never edit or remove a migration
/// that has shipped. Example:
///
/// ```dart
/// StorageMigration(
///   version: 2,
///   description: 'Rename theme key',
///   migrate: (store, secureStore) async {
///     final old = store.getString('theme');
///     if (old != null) await store.setString('settings.theme_mode', old);
///     await store.remove('theme');
///   },
/// ),
/// ```
final List<StorageMigration> storageMigrations = [
  StorageMigration(
    version: 1,
    description: 'Initial schema',
    migrate: (_, _) async {},
  ),
];
