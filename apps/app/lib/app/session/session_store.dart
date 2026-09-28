import 'package:storage/storage.dart';

/// Owns the user's credentials. Tokens live only in [SecureStore].
///
/// The template ships without a sign-in flow because authentication is
/// backend-specific. Call [saveAccessToken] from your sign-in feature; the
/// `ApiClient` already reads the token through [readAccessToken].
final class SessionStore {
  const new(this._secureStore);

  static const accessTokenKey = 'session.access_token';

  final SecureStore _secureStore;

  Future<String?> readAccessToken() => _secureStore.read(accessTokenKey);

  Future<void> saveAccessToken(String token) =>
      _secureStore.write(accessTokenKey, token);

  Future<void> clear() => _secureStore.delete(accessTokenKey);
}

/// Removes everything the app stored on the device: secrets, cached content
/// and preferences.
///
/// The storage bookkeeping keys (schema version and install marker) are kept
/// so migrations do not run again. Call this on sign-out if your app must not
/// keep any user data between sessions, and extend it when you add new
/// stores (databases, files).
final class LocalDataCleaner {
  const new({required this._keyValueStore, required this._secureStore});

  final KeyValueStore _keyValueStore;
  final SecureStore _secureStore;

  static const Set<String> _preservedKeys = {
    StorageMigrator.versionKey,
    StorageMigrator.installMarkerKey,
  };

  Future<void> clearAll() async {
    await _secureStore.deleteAll();
    for (final key in _keyValueStore.keys.difference(_preservedKeys)) {
      await _keyValueStore.remove(key);
    }
  }
}
