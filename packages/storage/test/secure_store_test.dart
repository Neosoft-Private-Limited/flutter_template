import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

void main() {
  Future<void> exerciseContract(SecureStore store) async {
    await store.write('access_token', 'a');
    await store.write('refresh_token', 'r');
    expect(await store.read('access_token'), 'a');

    await store.delete('access_token');
    expect(await store.read('access_token'), isNull);
    expect(await store.read('refresh_token'), 'r');

    await store.deleteAll();
    expect(await store.read('refresh_token'), isNull);
  }

  test('FlutterSecureStore fulfils the SecureStore contract', () async {
    FlutterSecureStorage.setMockInitialValues({});

    await exerciseContract(FlutterSecureStore());
  });

  test('InMemorySecureStore fulfils the SecureStore contract', () async {
    await exerciseContract(InMemorySecureStore());
  });
}
