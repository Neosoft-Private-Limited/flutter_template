# networking

HTTP boundary built on Dio. Pure Dart; depends only on `core`.

- `ApiClient`: `get/post/put/patch/delete` returning `Result<T>`
- `GraphQLClient`: `query/mutate` returning `Result<T>`; GraphQL `errors`
  become `GraphQLFailure` (or `UnauthorizedFailure` for `UNAUTHENTICATED`)
- `HttpSettings`: timeouts and interceptors shared by both clients
- `AuthInterceptor`, `LoggingInterceptor` (redacting), `RetryInterceptor` (idempotent requests only)
- `mapDioException`: Dio errors to `AppFailure`
- `Json.list`: helper for validating decoders
- `package:networking/testing.dart`: `FakeHttpAdapter`, `FakeResponse` for tests

Request paths are relative to the base URL (`'posts'`, not `'/posts'`).
See [docs/architecture.md](../../docs/architecture.md#networking).
