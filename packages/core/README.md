# core

Framework-agnostic types shared by every package. Pure Dart: must not depend
on Flutter or on other workspace packages.

- `Result<T>` (`Ok`/`Err`) and the sealed `AppFailure` hierarchy (including
  transport-neutral `NotFoundFailure` and `GraphQLFailure`)
- `AppConfig`, `AppEnvironment`, `ConfigException`: typed, validated build configuration
- `configureLogging`, `LogLevel`, `Redactor`: logging and sensitive-data masking
- `Validators`, `ValidationError`: pure input validation

Tests: `flutter test` (or `dart test`) in this directory.
