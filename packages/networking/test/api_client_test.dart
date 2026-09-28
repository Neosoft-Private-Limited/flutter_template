import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:networking/networking.dart';
import 'package:networking/testing.dart';
import 'package:test/test.dart';

void main() {
  final baseUrl = Uri.parse('https://api.test.dev/v1/');

  ApiClient clientWith(FakeHttpAdapter adapter, {TokenReader? readToken}) =>
      ApiClient.create(
        baseUrl: baseUrl,
        httpClientAdapter: adapter,
        readToken: readToken,
        maxRetries: 0,
      );

  int decodeId(Object? json) => switch (json) {
    {'id': final int id} => id,
    _ => throw FormatException('missing id', json),
  };

  group('ApiClient', () {
    test('decodes a successful JSON response', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse.json({'id': 7}));

      final result = await clientWith(adapter)
          .get('items/7', decode: decodeId, query: {'expand': 'all'});

      expect(result, const Ok(7));
      final request = adapter.requests.single;
      expect(request.uri.toString(), '${baseUrl}items/7?expand=all');
      expect(request.headers['Accept'], 'application/json');
    });

    test('joins relative paths to base URLs with or without a slash', () async {
      for (final (base, expected) in [
        ('https://api.test.dev', 'https://api.test.dev/items'),
        ('https://api.test.dev/', 'https://api.test.dev/items'),
        ('https://api.test.dev/v1', 'https://api.test.dev/v1/items'),
        ('https://api.test.dev/v1/', 'https://api.test.dev/v1/items'),
      ]) {
        final adapter = FakeHttpAdapter.always(FakeResponse.json({'id': 1}));
        await ApiClient.create(
          baseUrl: Uri.parse(base),
          httpClientAdapter: adapter,
        ).get('items', decode: decodeId);

        expect(adapter.requests.single.uri.toString(), expected, reason: base);
      }
    });

    test('sends the request body with the right method', () async {
      final adapter = FakeHttpAdapter.always(
        FakeResponse.json({'id': 1}, statusCode: 201),
      );

      final result = await clientWith(adapter)
          .post('items', body: {'name': 'x'}, decode: decodeId);

      expect(result.valueOrNull, 1);
      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {'name': 'x'});
    });

    test('maps an unexpected payload to ParsingFailure', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse.json({'name': 'x'}));

      final result = await clientWith(adapter).get('x', decode: decodeId);

      expect(result.failureOrNull, isA<ParsingFailure>());
    });

    test('maps HTTP 401 to UnauthorizedFailure', () async {
      final adapter = FakeHttpAdapter.always(const FakeResponse(401));

      final result = await clientWith(adapter).get('x', decode: decodeId);

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('maps HTTP 404 to ServerFailure with the status code', () async {
      final adapter = FakeHttpAdapter.always(const FakeResponse(404));

      final result = await clientWith(adapter).get('x', decode: decodeId);

      final failure = result.failureOrNull! as ServerFailure;
      expect(failure.statusCode, 404);
      expect(failure.isNotFound, isTrue);
    });

    test('maps connection errors to NetworkFailure', () async {
      final adapter = FakeHttpAdapter(
        (request, _) async => throw DioException.connectionError(
          requestOptions: request,
          reason: 'offline',
        ),
      );

      final result = await clientWith(adapter).get('x', decode: decodeId);

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps cancellation to CancelledFailure', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse.json({'id': 1}));
      final token = CancelToken()..cancel('user left');

      final result = await clientWith(adapter)
          .get('x', decode: decodeId, cancelToken: token);

      expect(result.failureOrNull, isA<CancelledFailure>());
    });

    test('attaches the bearer token when one is available', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse.json({'id': 1}));

      await clientWith(
        adapter,
        readToken: () async => 'secret-token',
      ).get('x', decode: decodeId);

      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer secret-token',
      );
    });

    test('skips the token for public requests and when signed out', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse.json({'id': 1}));
      final client = clientWith(adapter, readToken: () async => 't');
      final signedOut = clientWith(adapter, readToken: () async => null);

      await client.get(
        'public',
        decode: decodeId,
        options: Options(extra: {RequestExtras.authenticate: false}),
      );
      await signedOut.get('x', decode: decodeId);

      expect(
        adapter.requests.map((r) => r.headers.containsKey('Authorization')),
        [false, false],
      );
    });

    test('notifies onUnauthorized on HTTP 401', () async {
      var notified = 0;
      final client = ApiClient.create(
        baseUrl: baseUrl,
        httpClientAdapter: FakeHttpAdapter.always(const FakeResponse(401)),
        readToken: () async => 'expired',
        onUnauthorized: () async => notified++,
        maxRetries: 0,
      );

      await client.get('x', decode: decodeId);

      expect(notified, 1);
    });
  });

  group('Json.list', () {
    test('decodes each element and rejects non-arrays', () {
      expect(Json.list([1, 2], (v) => (v! as int) * 2), [2, 4]);
      expect(
        () => Json.list({'a': 1}, (v) => v),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
