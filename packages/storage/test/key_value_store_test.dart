import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:storage/storage.dart';

void main() {
  Future<void> exerciseContract(KeyValueStore store) async {
    await store.setString('s', 'value');
    await store.setBool('b', value: true);
    await store.setInt('i', 42);
    await store.setDouble('d', 1.5);
    await store.setStringList('l', ['a', 'b']);

    expect(store.getString('s'), 'value');
    expect(store.getBool('b'), isTrue);
    expect(store.getInt('i'), 42);
    expect(store.getDouble('d'), 1.5);
    expect(store.getStringList('l'), ['a', 'b']);
    expect(store.keys, {'s', 'b', 'i', 'd', 'l'});
    expect(store.getString('missing'), isNull);

    await store.remove('s');
    expect(store.containsKey('s'), isFalse);

    await store.clear();
    expect(store.keys, isEmpty);
  }

  group('SharedPreferencesKeyValueStore', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    test('fulfils the KeyValueStore contract', () async {
      await exerciseContract(await SharedPreferencesKeyValueStore.create());
    });

    test('persists values across instances', () async {
      final first = await SharedPreferencesKeyValueStore.create();
      await first.setString('theme', 'dark');

      final second = await SharedPreferencesKeyValueStore.create();

      expect(second.getString('theme'), 'dark');
    });
  });

  group('InMemoryKeyValueStore', () {
    test('fulfils the KeyValueStore contract', () async {
      await exerciseContract(InMemoryKeyValueStore());
    });

    test('starts from initial values without aliasing them', () {
      final initial = {'a': 1};
      final store = InMemoryKeyValueStore(initial);
      initial['a'] = 2;

      expect(store.getInt('a'), 1);
    });
  });
}
