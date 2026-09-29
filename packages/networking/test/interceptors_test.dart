import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:networking/networking.dart';
import 'package:networking/testing.dart';
import 'package:test/test.dart';

void main() {
  final baseUrl = Uri.parse('https://api.test.dev/');
  Object? passThrough(Object? json) => json;

  group('RetryInterceptor', () {
    late List<Duration> sleeps;

    ApiClient clientWith(FakeHttpAdapter adapter, {int maxRetries = 2}) {
      final dio = Dio(BaseOptions(baseUrl: baseUrl.toString()))
        ..httpClientAdapter = adapter;
      dio.interceptors.add(
        RetryInterceptor(
          dio: dio,
          maxRetries: maxRetries,
          baseDelay: const Duration(milliseconds: 100),
          sleep: (delay) async => sleeps.add(delay),
        ),
      );
      return ApiClient(dio);
    }

    setUp(() => sleeps = []);

    test('retries transient GET failures with exponential backoff', () async {
      final adapter = FakeHttpAdapter(
        (request, call) async => call < 2
            ? const FakeResponse(503)
            : FakeResponse.json({'ok': true}),
      );

      final result = await clientWith(adapter).get('x', decode: passThrough);

      expect(result.valueOrNull, {'ok': true});
      expect(adapter.requests, hasLength(3));
      expect(sleeps, const [
        Duration(milliseconds: 100),
        Duration(milliseconds: 200),
      ]);
    });

    test('gives up after maxRetries and returns the last failure', () async {
      final adapter = FakeHttpAdapter.always(const FakeResponse(503));

      final result = await clientWith(adapter).get('x', decode: passThrough);

      expect(adapter.requests, hasLength(3));
      expect((result.failureOrNull! as ServerFailure).statusCode, 503);
    });

    test('retries connection errors', () async {
      final adapter = FakeHttpAdapter((request, call) async {
        if (call == 0) {
          throw DioException.connectionError(
            requestOptions: request,
            reason: 'offline',
          );
        }
        return FakeResponse.json(1);
      });

      final result = await clientWith(adapter).get('x', decode: passThrough);

      expect(result.valueOrNull, 1);
    });

    test('never retries POST unless marked retryable', () async {
      final adapter = FakeHttpAdapter.always(const FakeResponse(503));
      final client = clientWith(adapter);

      await client.post('x', decode: passThrough);
      expect(adapter.requests, hasLength(1));

      await client.post(
        'x',
        decode: passThrough,
        options: Options(extra: {RequestExtras.retryable: true}),
      );
      expect(adapter.requests, hasLength(4));
    });

    test('does not retry client errors', () async {
      final adapter = FakeHttpAdapter.always(const FakeResponse(400));

      await clientWith(adapter).get('x', decode: passThrough);

      expect(adapter.requests, hasLength(1));
    });
  });

  group('LoggingInterceptor', () {
    late List<LogRecord> records;

    setUp(() {
      records = [];
      final subscription = configureLogging(
        level: LogLevel.debug,
        sink: records.add,
      );
      addTearDown(subscription.cancel);
    });

    test('redacts headers, query parameters and bodies', () async {
      final dio = Dio(BaseOptions(baseUrl: baseUrl.toString()))
        ..httpClientAdapter = FakeHttpAdapter.always(
          FakeResponse.json({'access_token': 'server-secret', 'id': 1}),
        )
        ..interceptors.add(LoggingInterceptor(logBodies: true));

      await ApiClient(dio).post(
        'login',
        query: {'api_key': 'query-secret'},
        body: {'email': 'a@b.co', 'password': 'hunter2'},
        options: Options(headers: {'Authorization': 'Bearer header-secret'}),
        decode: passThrough,
      );
      await Future<void>.delayed(Duration.zero);

      final output = records.map((r) => r.message).join('\n');
      expect(output, contains('--> POST'));
      expect(output, contains('<-- POST'));
      expect(output, contains('a@b.co'));
      for (final secret in [
        'server-secret',
        'query-secret',
        'hunter2',
        'header-secret',
      ]) {
        expect(output, isNot(contains(secret)), reason: secret);
      }
    });

    test('omits bodies unless enabled', () async {
      final dio = Dio(BaseOptions(baseUrl: baseUrl.toString()))
        ..httpClientAdapter = FakeHttpAdapter.always(
          FakeResponse.json({'email': 'person@example.com'}),
        )
        ..interceptors.add(LoggingInterceptor());

      await ApiClient(dio).get('me', decode: passThrough);
      await Future<void>.delayed(Duration.zero);

      expect(
        records.map((r) => r.message).join(),
        isNot(contains('person@example.com')),
      );
    });
  });

  group('mapDioException', () {
    final request = RequestOptions(path: '/x');

    test('maps timeouts to TimeoutFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          mapDioException(DioException(requestOptions: request, type: type)),
          isA<TimeoutFailure>(),
          reason: type.name,
        );
      }
    });

    test('maps certificate errors to NetworkFailure', () {
      expect(
        mapDioException(DioException.badCertificate(requestOptions: request)),
        isA<NetworkFailure>(),
      );
    });

    test('maps unknown errors to UnknownFailure', () {
      expect(
        mapDioException(DioException(requestOptions: request)),
        isA<UnknownFailure>(),
      );
    });
  });
}
