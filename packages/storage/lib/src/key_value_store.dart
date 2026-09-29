import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive, typed key-value storage (settings, flags, small caches).
///
/// Reads are synchronous from an in-memory cache; writes persist
/// asynchronously. **Do not store secrets or tokens here**: on Android and iOS
/// the backing file is not encrypted. Use `SecureStore` for those.
abstract interface class KeyValueStore {
  /// The string stored under [key], or `null` when the key is absent.
  ///
  /// Like every getter here, throws a [TypeError] if the value was stored
  /// with a different type.
  String? getString(String key);

  /// The bool stored under [key], or `null` when the key is absent.
  bool? getBool(String key);

  /// The int stored under [key], or `null` when the key is absent.
  int? getInt(String key);

  /// The double stored under [key], or `null` when the key is absent.
  double? getDouble(String key);

  /// A copy of the string list stored under [key], or `null` when the key is
  /// absent.
  List<String>? getStringList(String key);

  /// Stores [value] under [key], replacing any previous value.
  ///
  /// The in-memory value is visible to reads immediately; the returned
  /// future completes once it has been persisted.
  Future<void> setString(String key, String value);

  /// Stores [value] under [key], replacing any previous value.
  Future<void> setBool(String key, {required bool value});

  /// Stores [value] under [key], replacing any previous value.
  Future<void> setInt(String key, int value);

  /// Stores [value] under [key], replacing any previous value.
  Future<void> setDouble(String key, double value);

  /// Stores a copy of [value] under [key], replacing any previous value.
  Future<void> setStringList(String key, List<String> value);

  /// Whether a value of any type is stored under [key].
  bool containsKey(String key);

  /// A snapshot of every key currently stored.
  Set<String> get keys;

  /// Deletes the value stored under [key]; does nothing if it is absent.
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
  /// Starts with a copy of [initialValues]; values must be `String`, `bool`,
  /// `int`, `double` or `List<String>`.
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
