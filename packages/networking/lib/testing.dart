/// Test doubles for code that uses `ApiClient`. Import only from tests.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Builds a response (or throws a [DioException]) for a request.
typedef FakeHandler = Future<FakeResponse> Function(
  RequestOptions request,
  int callIndex,
);

/// A canned HTTP response.
final class FakeResponse {
  /// A response with [statusCode], an optional raw [body] and [headers]
  /// (none by default).
  const new(this.statusCode, [this.body, this.headers = const {}]);

  /// A JSON response with `content-type: application/json`.
  factory json(Object? body, {int statusCode = 200}) =>
      FakeResponse(statusCode, jsonEncode(body), const {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });

  /// The HTTP status code; Dio treats codes outside 2xx as a `badResponse`.
  final int statusCode;

  /// The raw response body, or `null` for an empty body.
  final String? body;

  /// Response headers, keyed by header name.
  final Map<String, List<String>> headers;
}

/// An in-memory [HttpClientAdapter]: no sockets, deterministic responses.
///
/// Throw a [DioException] from the handler to simulate transport errors, e.g.
/// `throw DioException.connectionError(requestOptions: r, reason: 'offline')`.
final class FakeHttpAdapter implements HttpClientAdapter {
  /// Answers every request with the result of [handler].
  new(this.handler);

  /// Always answers with the same [response].
  factory always(FakeResponse response) =>
      FakeHttpAdapter((_, _) async => response);

  /// Simulates a device without connectivity: every request fails with a
  /// connection error.
  factory offline() => FakeHttpAdapter(
    (request, _) async => throw DioException.connectionError(
      requestOptions: request,
      reason: 'offline (FakeHttpAdapter)',
    ),
  );

  /// Produces the response for each request; receives the request and its
  /// zero-based index among all requests this adapter has seen.
  final FakeHandler handler;

  /// Every request received, in order.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = await handler(options, requests.length - 1);
    return ResponseBody.fromString(
      response.body ?? '',
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close({bool force = false}) {}
}
