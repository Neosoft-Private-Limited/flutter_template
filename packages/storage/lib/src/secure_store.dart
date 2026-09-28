import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage for secrets: access/refresh tokens, encryption keys.
///
/// Backed by the Keychain on iOS and Keystore-wrapped encryption on Android.
/// On the web the plugin stores data encrypted with a key that lives in the
/// same browser profile; treat it as obfuscation, not protection.
abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);

  /// Removes every secret written by this app.
  Future<void> deleteAll();
}

/// [SecureStore] backed by `flutter_secure_storage`.
final class FlutterSecureStore implements SecureStore {
  new([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage(iOptions: _iosOptions);

  // Available after the first unlock, never synced to iCloud or restored to
  // another device.
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// In-memory [SecureStore] for tests. Nothing is persisted.
final class InMemorySecureStore implements SecureStore {
  new([Map<String, String> initialValues = const {}])
    : _values = Map.of(initialValues);

  final Map<String, String> _values;

  /// Read-only view of the stored values, for assertions.
  Map<String, String> get values => Map.unmodifiable(_values);

  @override
  Future<String?> read(String key) async => _values[key];
  @override
  Future<void> write(String key, String value) async => _values[key] = value;
  @override
  Future<void> delete(String key) async => _values.remove(key);
  @override
  Future<void> deleteAll() async => _values.clear();
}
