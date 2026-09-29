import 'package:database/database.dart';
import 'package:storage/storage.dart';

/// Owns the user's credentials. Tokens live only in [SecureStore].
///
/// The template ships without a sign-in flow because authentication is
/// backend-specific. Call [saveAccessToken] from your sign-in feature; the
/// `ApiClient` already reads the token through [readAccessToken].
final class SessionStore {
  /// Creates a session whose token is kept in the given [SecureStore].
  const new(this._secureStore);

  /// [SecureStore] key under which the access token is saved.
  static const accessTokenKey = 'session.access_token';

  final SecureStore _secureStore;

  /// The saved access token, or `null` when the user is signed out.
  Future<String?> readAccessToken() => _secureStore.read(accessTokenKey);

  /// Saves [token], replacing any previous one. Later requests send it.
  Future<void> saveAccessToken(String token) =>
      _secureStore.write(accessTokenKey, token);

  /// Deletes the access token (signs the user out). Other stored data is
  /// kept; use [LocalDataCleaner] to remove it too.
  Future<void> clear() => _secureStore.delete(accessTokenKey);
}

/// Removes everything the app stored on the device: secrets, the database,
/// cached content and preferences.
///
/// The storage bookkeeping keys (schema version and install marker) are kept
/// so migrations do not run again. Call this on sign-out if your app must not
/// keep any user data between sessions, and extend it when you add new
/// stores (files, other databases).
final class LocalDataCleaner {
  /// Creates a cleaner for the given stores. Without a database, only the
  /// key-value and secure stores are cleared.
  const new({
    required this._keyValueStore,
    required this._secureStore,
    this._database,
  });

  final KeyValueStore _keyValueStore;
  final SecureStore _secureStore;
  final AppDatabase? _database;

  static const Set<String> _preservedKeys = {
    StorageMigrator.versionKey,
    StorageMigrator.installMarkerKey,
  };

  /// Deletes every secret, every database row and every key-value entry
  /// except the storage bookkeeping keys.
  Future<void> clearAll() async {
    await _secureStore.deleteAll();
    await _database?.clearAll();
    for (final key in _keyValueStore.keys.difference(_preservedKeys)) {
      await _keyValueStore.remove(key);
    }
  }
}
