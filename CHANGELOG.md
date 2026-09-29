# Changelog

## Unreleased: strict lint rules

### Changed
- `analysis_options.yaml`: on top of very_good_analysis, enables every
  remaining compatible stable rule (`close_sinks`, `no_dynamic_casts`,
  `no_raw_types`, `do_not_use_environment`, `unreachable_from_main`, ...) and
  the safety-focused experimental rules (`unsafe_variance`,
  `unnecessary_async`, `avoid_futureor_void`, `annotate_redeclares`,
  `var_with_no_type_annotation`).
- Correctness, type-safety and hygiene diagnostics are raised to errors;
  eleven of them (unawaited/discarded futures, dynamic calls, `print`,
  `BuildContext` across async gaps, ...) can no longer be silenced with
  `// ignore:`.
- `public_member_api_docs` is required in shared packages; every public
  member of `packages/*` is now documented. Apps opt out in their own
  `analysis_options.yaml`.
- Documented in `docs/development.md#lint-rules`.

## Unreleased: MVVM base pages

### Added
- `PageLayout` (app_foundation): shared page template with scaffold hooks,
  back handling and lifecycle hooks (`onInit`, `onResume`, `onPause`,
  `onDispose`), the successor of the old `CoreBasePageState`.
- Riverpod app: `BasePage`, `BaseAsyncPage` and `AsyncViewModel`
  (`lib/app/base/`); pages are single classes, view models replace the
  former controllers (`PostsViewModel`, `PostDetailViewModel`,
  `SettingsViewModel`).
- Bloc app: `BasePage`, `BaseAsyncPage`, `AsyncCubit` and `ViewState`;
  pages create and close their own blocs (`SettingsCubit` added,
  `PostDetailCubit` now an `AsyncCubit`).
- Base page tests in both apps.

## Unreleased: drift, GraphQL and a Bloc variant

### Added
- `packages/database`: drift (SQLite) with the `CachedPosts` table, `PostsDao`,
  schema snapshots (`drift_schemas/`) and `clearAll()`; web assets
  (`sqlite3.wasm`, `drift_worker.js`) in both apps.
- `GraphQLClient` and `HttpSettings` in `networking`; `GraphQLFailure` and a
  transport-neutral `NotFoundFailure` in `core`; optional `GRAPHQL_URL`
  configuration and `config/dev_graphql.json`.
- `apps/app_bloc`: the example app built with flutter_bloc (blocs, cubits,
  `RepositoryProvider`), with its own flavors and IDs, tests and integration
  tests.
- `packages/app_foundation`: start-up (`initializeAppServices`, `AppServices`),
  configuration, error handling, session, settings and shared screens used
  by both apps.
- `packages/feature_posts`: posts domain, REST and GraphQL data sources,
  drift-backed offline cache (list and detail), stateless widgets and test
  doubles.
- Melos scripts `codegen:l10n` and `codegen:build_runner`; `codegen:check`
  also verifies drift output; integration runner covers every app.

### Changed
- HTTP 404 now maps to `NotFoundFailure` instead of `ServerFailure`.
- The posts offline cache moved from key-value storage to SQLite (storage
  migration v2 removes the old key).
- CI and the release workflow build both apps; `check:packages` also keeps
  Bloc out of shared packages.

### Removed
- Unused `mocktail` dev dependency from `apps/app`.

## Unreleased: modernization to Flutter 3.47

Rebuilt the template on Flutter 3.47.5 / Dart 3.13.4 / Melos 8.9.0. See
[docs/architecture-audit.md](docs/architecture-audit.md) for the full
reasoning and inventory.

### Added
- Pub workspace (`apps/*`, `packages/*`) with Melos 8 configuration in the root `pubspec.yaml`.
- Packages `core`, `networking`, `storage`, `design_system`, `localization`.
- Validated build configuration per environment (`config/*.json`) with fail-fast checks for production.
- Riverpod 3 state management and dependency injection; go_router 18 routing with deep-link validation.
- Offline-capable example API feature, design-system showcase, settings (theme, language, clear data).
- Redacting network logs, idempotent-only retries, secure token storage, storage migrations.
- 126 unit/widget tests, 2 integration tests, workspace package checks, codegen check.
- CI (format, analyze, test, Android/iOS/web builds), manual release and integration workflows, Dependabot.
- Rename tool, VS Code/IntelliJ launch configurations, documentation in `docs/`.

### Changed
- Flavor `qa` renamed to `staging`; single `lib/main.dart` entry point.
- Regenerated Android (AGP 9.1, Gradle 9.3.1, Kotlin DSL, Java 17) and iOS (15.0, per-flavor xcconfigs) projects.
- Material imports moved to `package:material_ui`.

### Removed
- Floor database module (incompatible with Dart 3.13, unmaintained), get_it/injectable,
  Bloc and base-page state-management modules, dartz, retrofit, provider/rxdart,
  responsive_framework, intl_utils output, `app_secrets.dart`, auto-committing CD workflow,
  obsolete build scripts and `wiki/`.
