import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive, typed key-value storage (settings, flags, small caches).
///
/// Reads are synchronous from an in-memory cache; writes persist
/// asynchronously. **Do not store secrets or tokens here**: on Android and iOS
/// the backing file is not encrypted. Use `SecureStore` for those.
abstract interface class KeyValueStore {
  String? getString(String key);
  bool? getBool(String key);
  int? getInt(String key);
  double? getDouble(String key);
  List<String>? getStringList(String key);

  Future<void> setString(String key, String value);
  Future<void> setBool(String key, {required bool value});
  Future<void> setInt(String key, int value);
  Future<void> setDouble(String key, double value);
  Future<void> setStringList(String key, List<String> value);

  bool containsKey(String key);
  Set<String> get keys;

  Future<void> remove(String key);

  /// Removes every key held by this store.
  Future<void> clear();
}

/// [KeyValueStore] backed by `SharedPreferencesWithCache`.
final class SharedPreferencesKeyValueStore implements KeyValueStore {
  new _(this._prefs);

  /// Loads the cache. Call once during app start-up.
  ///
  /// Pass [allowList] to restrict the store to known keys; reads and writes of
  /// other keys then throw, which catches typos early.
  static Future<SharedPreferencesKeyValueStore> create({
    Set<String>? allowList,
  }) async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: SharedPreferencesWithCacheOptions(allowList: allowList),
    );
    return SharedPreferencesKeyValueStore._(prefs);
  }

  final SharedPreferencesWithCache _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  bool? getBool(String key) => _prefs.getBool(key);
  @override
  int? getInt(String key) => _prefs.getInt(key);
  @override
  double? getDouble(String key) => _prefs.getDouble(key);
  @override
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  @override
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);
  @override
  Future<void> setInt(String key, int value) => _prefs.setInt(key, value);
  @override
  Future<void> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  @override
  Future<void> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  @override
  bool containsKey(String key) => _prefs.containsKey(key);
  @override
  Set<String> get keys => _prefs.keys;

  @override
  Future<void> remove(String key) => _prefs.remove(key);
  @override
  Future<void> clear() => _prefs.clear();
}

/// In-memory [KeyValueStore] for tests and previews. Nothing is persisted.
final class InMemoryKeyValueStore implements KeyValueStore {
  new([Map<String, Object> initialValues = const {}])
    : _values = Map.of(initialValues);

  final Map<String, Object> _values;

  T? _get<T>(String key) => _values[key] as T?;

  @override
  String? getString(String key) => _get(key);
  @override
  bool? getBool(String key) => _get(key);
  @override
  int? getInt(String key) => _get(key);
  @override
  double? getDouble(String key) => _get(key);
  @override
  List<String>? getStringList(String key) => _get(key);

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;
  @override
  Future<void> setBool(String key, {required bool value}) async =>
      _values[key] = value;
  @override
  Future<void> setInt(String key, int value) async => _values[key] = value;
  @override
  Future<void> setDouble(String key, double value) async =>
      _values[key] = value;
  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _values[key] = List.of(value);

  @override
  bool containsKey(String key) => _values.containsKey(key);
  @override
  Set<String> get keys => _values.keys.toSet();

  @override
  Future<void> remove(String key) async => _values.remove(key);
  @override
  Future<void> clear() async => _values.clear();
}
