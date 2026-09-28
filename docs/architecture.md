# Architecture

This guide explains how the workspace is organized and why. For the history
of the migration from the previous template, see
[architecture-audit.md](architecture-audit.md).

## Principles

- **Packages have one job and a small public API.** Each package exports a
  single library (`package:<name>/<name>.dart`); everything under `lib/src/`
  is private to the package.
- **Dependencies point inward.** Apps depend on packages; packages depend on
  `core`; `core` depends on nothing in the workspace.
- **Infrastructure is framework-agnostic.** `core` and `networking` are pure
  Dart. No shared package knows about Riverpod or go_router; the app wires
  everything together.
- **Failures are values.** Operations that can fail in expected ways return
  `Result<T>` (`Ok`/`Err`) carrying a typed `AppFailure`; exceptions are for
  bugs.
- **Explicit composition.** Dependencies are Riverpod providers, overridden at
  start-up and in tests. There is no service locator or global mutable state.

## Workspace map

```
apps/
  app/                  Example application (composition root, features, routing)
packages/
  core/                 Result, AppFailure, AppConfig, logging + redaction, validators   (pure Dart)
  networking/           ApiClient (Dio), auth/logging/retry interceptors, error mapping  (pure Dart)
  storage/              KeyValueStore, SecureStore, StorageMigrator                      (Flutter)
  design_system/        Tokens, light/dark themes, components, responsive layout         (Flutter)
  localization/         ARB files and generated AppLocalizations                         (Flutter)
tool/                   Workspace scripts (package checks, codegen check, rename, integration runner)
```

Dependency graph (verified by `melos run check:packages`):

```
                 app
   ┌──────┬───────┼─────────┬──────────────┐
   ▼      ▼       ▼         ▼              ▼
design_ local- networking storage         core
system  ization    │         │              ▲
                   └────┬────┘              │
                        └───────────────────┘
```

`design_system` and `localization` have no workspace dependencies. The checker
fails the build if a package depends on an app, if `core` or `networking`
depend on Flutter, if a package depends on Riverpod or go_router, or if a
dependency cycle appears.

### Why these packages (and not more)

| Package | Reason to exist |
| --- | --- |
| `core` | Types every layer shares. Pure Dart so it can be reused in CLIs, servers and isolates. |
| `networking` | One place for HTTP policy (timeouts, auth, retries, logging, error mapping). Pure Dart and testable with a fake transport. |
| `storage` | Keeps secrets and preferences apart behind small interfaces, plus migrations. |
| `design_system` | Shared visual language for every app; knows nothing about features. |
| `localization` | Strings are shared by apps and generated code must live in one package. |

Deliberately **not** packages: feature modules (they live in the app until a
second app needs them), a `testing` package (test doubles ship next to the code
they fake: `InMemoryKeyValueStore`, `InMemorySecureStore`,
`package:networking/testing.dart`), a dependency-injection package (Riverpod
covers it), and a database package (no feature needs one yet; see
[Storage](#storage)).

## Inside the app

```
apps/app/lib/
  main.dart                     Single entry point for all environments
  bootstrap.dart                Start-up sequence (see below)
  app/
    app.dart                    MaterialApp.router: themes, locale, router
    config/config_reader.dart   --dart-define values + flavor -> AppConfig
    di/providers.dart           Infrastructure providers (config, stores, ApiClient)
    error/                      ErrorReporter, failure -> message mapping, config error screen
    router/                     Routes, go_router configuration, adaptive shell, 404 page
    session/                    SessionStore (tokens), LocalDataCleaner
    storage_migrations.dart     Ordered StorageMigration list
  features/
    home/                       Design-system showcase and form validation example
    posts/                      Example API feature (list, detail, offline cache)
      domain/                   Entities and the repository interface
      data/                     API client calls, cache, repository implementation
      presentation/             Providers/controllers and pages
    settings/                   Theme, language, build info, clear local data
```

A feature owns its layers. `domain/` has no Flutter or I/O imports;
`data/` implements the domain interfaces; `presentation/` holds Riverpod
controllers and widgets. Skip layers a feature does not need; a static screen
is just a widget.

## Start-up sequence

`bootstrap()` runs these steps in order:

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. **Configuration**: `readAppConfig()` validates `--dart-define` values and
   the native flavor. On failure the app shows `ConfigErrorApp` listing every
   problem and stops. This is the fail-fast path for misconfigured builds.
3. **Logging** at `LOG_LEVEL`.
4. **Error handlers**: `FlutterError.onError`, `PlatformDispatcher.onError`
   and a neutral `ErrorWidget` in release builds, all routed to an
   `ErrorReporter`.
5. **Storage**: open `SharedPreferencesKeyValueStore` and `FlutterSecureStore`,
   then run `StorageMigrator`.
6. `runApp(ProviderScope(overrides: [...], child: App()))`.

## State management and dependency injection

Riverpod 3 is used for both, without code generation.

- **Infrastructure providers** (`app/di/providers.dart`) expose the config,
  stores, `ErrorReporter`, `SessionStore` and `ApiClient`. Providers whose
  values need async initialization throw `UnimplementedError` until
  `bootstrap` overrides them, so a missing override fails loudly.
- **Feature providers** live next to the feature
  (`features/posts/presentation/posts_providers.dart`).
- **Controllers** are `Notifier`/`AsyncNotifier` classes. Business rules stay
  in repositories and controllers; widgets only render state and forward
  user intents.
- **Lifecycle**: screen-scoped state uses `isAutoDispose: true` and is
  disposed when no widget listens. Resources call `ref.onDispose` (see
  `routerProvider`).
- **Retries**: Riverpod's automatic provider retry is disabled
  (`ProviderScope(retry: (_, _) => null)`). Transient network errors are
  retried by `RetryInterceptor`; everything else is retried by the user.

Async UI follows one pattern: show data if there is any (with a notice when
it is stale or a refresh failed), otherwise the error view, otherwise the
loading view. See `PostsPage`.

## Routing

`go_router` 18 with a `StatefulShellRoute` (one navigation stack per tab):

| Path | Screen |
| --- | --- |
| `/` | redirects to `/home` |
| `/home` | Components showcase |
| `/posts` | Posts list |
| `/posts/:id` | Post detail; `:id` must be a positive integer (≤ 9 digits), otherwise redirected to `/not-found` |
| `/settings` | Settings |
| anything else | Not-found page |

Use `AppRoutes` helpers (`AppRoutes.post(42)`) instead of string literals.
Deep links arrive through the same router; treat path and query parameters as
untrusted input and validate them in `redirect` or the route builder.

Platform deep-link setup (Android intent filters/App Links, iOS Associated
Domains) depends on your domain and is not configured. See
[security.md](security.md#deep-links).

## Networking

`ApiClient` (package `networking`) wraps a single Dio instance:

- Base URL from `API_BASE_URL`, normalized to end with `/`. Request paths are
  relative (`'posts'`, not `'/posts'`), so a base path like `/v1` is kept.
- Timeouts: connect 15 s, send/receive 30 s.
- Interceptors, in order:
  1. `AuthInterceptor` adds `Authorization: Bearer <token>` from `SessionStore`
     and clears the session on HTTP 401. Skip it per request with
     `Options(extra: {RequestExtras.authenticate: false})`. Token refresh is
     backend-specific and left as an extension point.
  2. `LoggingInterceptor` (only when `NETWORK_LOGS=true`) logs method, redacted
     URL, status and duration, plus redacted bodies.
  3. `RetryInterceptor` retries `GET`/`HEAD`/`OPTIONS` on connection errors,
     timeouts and HTTP 408/429/502/503/504, up to 2 times with exponential
     backoff. Other methods are retried only when the request opts in with
     `RequestExtras.retryable`.
- Every method returns `Future<Result<T>>`. Dio errors are mapped by
  `mapDioException`; `FormatException`s thrown by decoders become
  `ParsingFailure`.
- Cancellation: pass a `CancelToken`; cancelled calls return
  `CancelledFailure`.

**Serialization** is hand-written with Dart 3 patterns
(`Post.fromJson`). Decoders validate types and throw `FormatException` on
unexpected shapes. This avoids a code-generation step and makes invalid
payloads explicit. If your models grow large, `json_serializable` can be added
to a feature later.

## Storage

| Data | Store | Notes |
| --- | --- | --- |
| Preferences, flags, small caches | `KeyValueStore` (`shared_preferences` with cache) | Not encrypted. Synchronous reads after start-up. |
| Tokens, keys, other secrets | `SecureStore` (`flutter_secure_storage`) | Keychain (iOS, `first_unlock_this_device`), Keystore-backed encryption (Android). |
| Relational or large data | not included | Add a database package (for example `drift`) when a feature needs it. |

- **Migrations**: `StorageMigrator` runs ordered `StorageMigration`s at
  start-up and records the schema version, so an interrupted upgrade resumes.
- **Fresh installs**: iOS keeps Keychain items after uninstall. The migrator
  deletes leftover secrets when it detects a fresh install.
- **Clearing data**: `LocalDataCleaner.clearAll()` removes secrets and every
  preference except storage bookkeeping. Settings → *Clear local data* uses it.
  Extend it when you add stores.

The previous template's Floor database was removed: `floor_generator` is
incompatible with Dart 3.13 and unmaintained, and no feature used the
database. See the [audit](architecture-audit.md#6-migrate-or-rebuild).

## Error handling

| Layer | Mechanism |
| --- | --- |
| Transport and parsing | `ApiClient` returns `Err(AppFailure)` |
| Repositories | return `Result<T>`; decide on fallbacks (for example the offline cache) |
| Controllers | `result.getOrThrow()` turns a failure into `AsyncError` |
| UI | `FailureView` / `describeError` map failure types to localized text; developer messages are never shown |
| Uncaught | `ErrorReporter` (default: logs). Replace with a crash-reporting implementation if you use one. |

## Design system

`design_system` builds Material 3 themes from `AppColors.seed` and the tokens
(`AppSpacing`, `AppRadius`, `AppSizes`, `AppDurations`). Components take
already-localized strings as parameters, so the package has no user-facing
text. Key pieces:

- `AppButton` (primary/secondary/text, loading state), `AppTextField`,
  `showAppConfirmDialog`, `showAppSnackBar`, `AppLoadingView`,
  `AppMessageView.empty/error`, `AppSectionHeader`.
- `WindowSize` (Material 3 size classes), `ContentConstraint` (max readable
  width) and `AdaptiveNavigationScaffold` (bottom bar ↔ rail).
- 48 dp minimum touch targets; tests check the Android, iOS, labelled
  tap-target and text-contrast guidelines in both themes.

The app imports Material from `package:material_ui/material_ui.dart`. Material
moved out of the framework into this package (go_router 18 already uses it),
and mixing it with the legacy `package:flutter/material.dart` would create two
unrelated `Theme` types.

## Localization

`flutter gen-l10n` generates `AppLocalizations` from
`packages/localization/lib/l10n/app_<locale>.arb`. English is the template and
fallback; Spanish is included as a second locale to prove switching works. The
generated Dart files are committed, and CI fails if they are stale. Workflow:
[development.md](development.md#localization).

## Conventions

- Files `snake_case.dart`, one public widget/class per file where practical.
- Always `package:` imports (enforced by `always_use_package_imports`).
- Constructors use Dart 3.13 syntax (`const new(...)`, `factory json(...)`),
  enforced by `unnecessary_type_name_in_constructor`.
- Provider names end in `Provider`; controllers end in `Controller`.
- Storage keys are namespaced: `settings.*`, `cache.*`, `session.*`,
  `storage.*`.
