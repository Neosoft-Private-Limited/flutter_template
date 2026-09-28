import 'package:core/core.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('Redactor', () {
    const redactor = Redactor();

    test('masks sensitive headers regardless of case and separators', () {
      final result = redactor.headers({
        'Authorization': 'Bearer abc',
        'X-API-Key': 'k',
        'set-cookie': 's',
        'Accept': 'application/json',
      });

      expect(result, {
        'Authorization': Redactor.mask,
        'X-API-Key': Redactor.mask,
        'set-cookie': Redactor.mask,
        'Accept': 'application/json',
      });
    });

    test('masks nested JSON fields and leaves the rest intact', () {
      final result = redactor.json({
        'user': {'email': 'a@b.co', 'password': 'hunter2'},
        'tokens': [
          {'access_token': 'x', 'expires_in': 3600},
        ],
        'refreshToken': 'y',
      });

      expect(result, {
        'user': {'email': 'a@b.co', 'password': Redactor.mask},
        'tokens': [
          {'access_token': Redactor.mask, 'expires_in': 3600},
        ],
        'refreshToken': Redactor.mask,
      });
    });

    test('masks sensitive query parameters', () {
      final uri = redactor.uri(Uri.parse('https://a.dev/p?token=t&page=2'));

      expect(uri.queryParameters, {'token': Redactor.mask, 'page': '2'});
    });

    test('supports custom keys', () {
      const custom = Redactor(sensitiveKeys: {'ssn'});

      expect(custom.json({'SSN': '1', 'password': 'p'}), {
        'SSN': Redactor.mask,
        'password': 'p',
      });
    });
  });

  group('configureLogging', () {
    test('forwards records at or above the configured level', () async {
      final records = <LogRecord>[];
      final subscription = configureLogging(
        level: LogLevel.warning,
        sink: records.add,
      );
      addTearDown(subscription.cancel);

      Logger('test')
        ..info('hidden')
        ..warning('shown');
      await Future<void>.delayed(Duration.zero);

      expect(records.map((r) => r.message), ['shown']);
      expect(formatLogRecord(records.single), contains('WARNING [test] shown'));
    });
  });
}
