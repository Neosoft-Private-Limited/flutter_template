import 'dart:convert';

import 'package:core/core.dart';
import 'package:networking/networking.dart';
import 'package:networking/testing.dart';
import 'package:test/test.dart';

void main() {
  final endpoint = Uri.parse('https://api.test.dev/graphql');
  const document = r'query Post($id: ID!) { post(id: $id) { id title } }';

  String decodeTitle(Map<String, Object?> data) => switch (data) {
    {'post': {'title': final String title}} => title,
    _ => throw FormatException('missing title', data),
  };

  GraphQLClient clientWith(
    FakeHttpAdapter adapter, {
    TokenReader? readToken,
    Future<void> Function()? onUnauthorized,
    int maxRetries = 0,
  }) => GraphQLClient.create(
    endpoint: endpoint,
    settings: HttpSettings(
      httpClientAdapter: adapter,
      readToken: readToken,
      onUnauthorized: onUnauthorized,
      maxRetries: maxRetries,
    ),
  );

  test('posts the document and variables and decodes data', () async {
    final adapter = FakeHttpAdapter.always(
      FakeResponse.json({
        'data': {
          'post': {'id': '1', 'title': 'Hello'},
        },
      }),
    );

    final result = await clientWith(adapter).query(
      document,
      variables: {'id': '1'},
      operationName: 'Post',
      decode: decodeTitle,
    );

    expect(result, const Ok('Hello'));
    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.uri, endpoint);
    final body = request.data is String
        ? jsonDecode(request.data as String)
        : request.data;
    expect(body, {
      'query': document,
      'variables': {'id': '1'},
      'operationName': 'Post',
    });
  });

  test('attaches the bearer token like REST calls', () async {
    final adapter = FakeHttpAdapter.always(
      FakeResponse.json({
        'data': {
          'post': {'title': 't'},
        },
      }),
    );

    await clientWith(
      adapter,
      readToken: () async => 'abc',
    ).query(document, decode: decodeTitle);

    expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
  });

  test(
    'maps GraphQL errors to GraphQLFailure with messages and codes',
    () async {
      final adapter = FakeHttpAdapter.always(
        FakeResponse.json({
          'errors': [
            {
              'message': 'Variable "id" is invalid',
              'extensions': {'code': 'BAD_USER_INPUT'},
            },
          ],
          'data': null,
        }),
      );

      final result = await clientWith(adapter)
          .query(document, decode: decodeTitle);

      final failure = result.failureOrNull! as GraphQLFailure;
      expect(failure.errors, ['Variable "id" is invalid']);
      expect(failure.codes, ['BAD_USER_INPUT']);
    },
  );

  test('maps UNAUTHENTICATED to UnauthorizedFailure and notifies', () async {
    var notified = 0;
    final adapter = FakeHttpAdapter.always(
      FakeResponse.json({
        'errors': [
          {
            'message': 'Not signed in',
            'extensions': {'code': 'UNAUTHENTICATED'},
          },
        ],
      }),
    );

    final result = await clientWith(
      adapter,
      onUnauthorized: () async => notified++,
    ).query(document, decode: decodeTitle);

    expect(result.failureOrNull, isA<UnauthorizedFailure>());
    expect(notified, 1);
  });

  test('rejects responses without data or with the wrong shape', () async {
    for (final body in <Object?>[
      {'data': null},
      [1, 2],
      {
        'data': {'post': null},
      },
    ]) {
      final result = await clientWith(
        FakeHttpAdapter.always(FakeResponse.json(body)),
      ).query(document, decode: decodeTitle);

      expect(result.failureOrNull, isA<ParsingFailure>(), reason: '$body');
    }
  });

  test('maps transport errors like REST calls', () async {
    final offline = await clientWith(FakeHttpAdapter.offline())
        .query(document, decode: decodeTitle);
    final serverError = await clientWith(
      FakeHttpAdapter.always(const FakeResponse(503)),
    ).query(document, decode: decodeTitle);

    expect(offline.failureOrNull, isA<NetworkFailure>());
    expect(serverError.failureOrNull, isA<ServerFailure>());
  });

  test('retries queries but never mutations', () async {
    final adapter = FakeHttpAdapter.always(const FakeResponse(503));
    final client = GraphQLClient.create(
      endpoint: endpoint,
      settings: HttpSettings(httpClientAdapter: adapter, maxRetries: 1),
    );

    await client.query(document, decode: decodeTitle);
    expect(adapter.requests, hasLength(2));

    await client.mutate('mutation { reset }', decode: (data) => data);
    expect(adapter.requests, hasLength(3));
  });
}
