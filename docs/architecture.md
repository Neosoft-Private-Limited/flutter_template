# Architecture

This guide explains how the workspace is organized and why. For the history
of the migration from the previous template, see
[architecture-audit.md](architecture-audit.md).

## Principles

- **Packages have one job and a small public API.** Each package exports a
  library (`package:<name>/<name>.dart`); everything under `lib/src/` is
  private to the package.
- **Dependencies point inward.** Apps depend on packages; packages never
  depend on apps; `core` depends on nothing in the workspace.
- **State management is an app decision.** No shared package depends on
  Riverpod, Bloc or go_router. The same packages power a Riverpod app and a
  Bloc app.
- **Failures are values.** Operations that can fail in expected ways return
  `Result<T>` (`Ok`/`Err`) carrying a typed `AppFailure`; exceptions are for
  bugs.
- **Explicit composition.** Infrastructure is created once at start-up
  (`AppServices`) and handed to the app's DI mechanism. There is no service
  locator or global mutable state.

## Workspace map

```
apps/
  app/                  Example app, Riverpod (state + DI)
  app_bloc/             Same example app, flutter_bloc (state) + RepositoryProvider (DI)
packages/
  core/                 Result, AppFailure, AppConfig, logging + redaction, validators   (pure Dart)
  networking/           ApiClient (REST), GraphQLClient, interceptors, error mapping     (pure Dart)
  storage/              KeyValueStore, SecureStore, StorageMigrator                      (Flutter)
  database/             drift (SQLite): schema, DAOs, schema migrations                  (Flutter)
  design_system/        Tokens, light/dark themes, components, responsive layout         (Flutter)
  localization/         ARB files and generated AppLocalizations                         (Flutter)
  app_foundation/       Start-up, config, errors, session, settings, shared screens      (Flutter)
  feature_posts/        Example feature: domain, REST/GraphQL data, offline cache, widgets
tool/                   Workspace scripts (checks, codegen check, rename, integration runner)
```

Dependencies between workspace members (verified by
`melos run check:packages`, which prints this list):

| Member | Depends on (workspace) |
| --- | --- |
| `app`, `app_bloc` | `app_foundation`, `feature_posts`, `core`, `database`, `design_system`, `localization`, `networking`, `storage` |
| `feature_posts` | `app_foundation`, `core`, `database`, `design_system`, `localization`, `networking` |
| `app_foundation` | `core`, `database`, `design_system`, `localization`, `networking`, `storage` |
| `networking`, `storage` | `core` |
| `core`, `database`, `design_system`, `localization` | none |

Direction: apps → feature packages → `app_foundation` → infrastructure
packages → `core`.

Apps also depend directly on the packages they use. The checker fails the
build if a package depends on an app, if `core` or `networking` depend on
Flutter, if a package depends on Riverpod, Bloc or go_router, or if a cycle
appears.

### Why these packages

| Package | Reason to exist |
| --- | --- |
| `core` | Types every layer shares. Pure Dart so it can be reused in CLIs, servers and isolates. |
| `networking` | One place for HTTP policy (timeouts, auth, retries, logging, error mapping) for REST and GraphQL. |
| `storage` | Keeps secrets and preferences apart behind small interfaces, plus migrations. |
| `database` | One SQLite schema and migration history shared by all features. |
| `design_system` | Shared visual language for every app; knows nothing about features. |
| `localization` | Strings shared by apps; generated code in one place. |
| `app_foundation` | Everything an app needs that does not depend on the state-management choice, so the Riverpod and Bloc apps do not duplicate it. |
| `feature_posts` | Shows how a feature shared by several apps is packaged: all layers except state management and routing. |

Deliberately **not** packages: a `testing` package (fakes ship next to the
code they fake: `InMemoryKeyValueStore`, `package:networking/testing.dart`,
`package:feature_posts/testing.dart`) and a DI package (Riverpod or
`RepositoryProvider` covers it).

## Riverpod or Bloc

Both apps have the same screens, routes, flavors and behaviour; only the
presentation wiring differs. Pick one for your project and delete the other
app (and its CI lines).

| Concern | `apps/app` (Riverpod 3) | `apps/app_bloc` (flutter_bloc 9) |
| --- | --- | --- |
| DI | Providers in `app/di/providers.dart`, supplied with `ProviderScope` overrides (`overridesFor(services)`) | `RepositoryProvider.value` in `App` (read with `context.read<T>()`) |
| Screen state | View models: `PostsViewModel`, `PostDetailViewModel` (`AsyncViewModel`), `SettingsViewModel` (`Notifier`) | `PostsBloc` (events → sealed states), `PostDetailCubit` (`AsyncCubit`), `SettingsCubit` |
| Pages | Extend `BasePage` / `BaseAsyncPage` | Extend `BasePage` / `BaseAsyncPage` |
| App-wide state | `themeModeProvider`, `localeProvider` (`Notifier`) | `ThemeCubit`, `LocaleCubit` above the router |
| Lifecycle | `isAutoDispose: true`, `ref.onDispose` | `BlocProvider` in route builders closes blocs automatically |
| Retries | Riverpod auto-retry disabled (`ProviderScope(retry: ...)`) | Bloc has no automatic retry |
| Errors in state code | Surface as `AsyncError` | `AppBlocObserver.onError` reports to `ErrorReporter` |
| Tests | `ProviderScope` overrides in `TestAppHarness` | `bloc_test` for blocs, `TestAppHarness` builds `App` with fakes |

Guidance: choose Riverpod for less boilerplate and built-in caching of async
data; choose Bloc when you want explicit events and state transitions that
are easy to trace and test, or your team already uses it. Either way, keep
business rules in repositories so switching later only touches
`presentation/`.

## Pages and view models (MVVM)

Screens follow Model–View–ViewModel, like the previous template's
`BasePage`/`BaseViewModel`, rebuilt for current Riverpod and Bloc:

| Role | What it is | Where |
| --- | --- | --- |
| Model | Repositories and domain types | `feature_posts`, `features/<name>/data|domain` |
| ViewModel | Holds screen state and intents | Riverpod: `Notifier` / `AsyncViewModel`; Bloc: `Bloc` / `Cubit` / `AsyncCubit` |
| View | A page extending `BasePage` + stateless widgets | `features/<name>/presentation` (Bloc app: `view/`) |

A page is **one class** that extends the app's base page; there is no
`ConsumerStatefulWidget` or separate State class to write:

| | Riverpod (`apps/app/lib/app/base/`) | Bloc (`apps/app_bloc/lib/app/base/`) |
| --- | --- | --- |
| Base page | `BasePage<VM extends Notifier<S>, S>` | `BasePage<VM extends Bloc/Cubit, S>` |
| Loading data | `BaseAsyncPage<VM extends AsyncViewModel<T>, T>` | `BaseAsyncPage<VM extends AsyncCubit<T>, T>` |
| Page provides | `viewModelProvider` getter | `createViewModel(context)` |
| Page implements | `buildView(context, state, viewModel)` | `buildView(context, state, viewModel)` (`buildData` for async) |
| View model base | `AsyncViewModel<T>`: `load()`, `refresh()`, `retry()`, `refreshError` | `AsyncCubit<T>`: `load()`, `fetch()`, `refresh()`; state `ViewState<T>` |

Both apps' base pages mix in `PageLayout` (app_foundation), which holds the
page template shared regardless of state management:

- scaffold hooks: `title`, `buildAppBar`, `buildFloatingActionButton`,
  `buildBottomNavigationBar`, `buildDrawer`, `backgroundColor`,
  `extendBodyBehindAppBar`, `resizeToAvoidBottomInset`;
- back handling: `canPop`, `onPopInvoked`;
- lifecycle: `onInit` (once, after the first frame; replaces the old
  `onModelReady`), `onResume`, `onPause` (app foreground/background),
  `onDispose`.

The async base pages render the loading spinner and the localized error
view with a retry button, so a data screen implements only the success
view. Differences from the old template: pages no longer inherit a fixed
`Scaffold` background, the view model is not re-attached on every rebuild,
and view models are disposed automatically (autoDispose providers /
`BlocProvider`).

## Inside an app

```
apps/app/lib/                         apps/app_bloc/lib/
  main.dart, bootstrap.dart             main.dart, bootstrap.dart
  app/base/ (BasePage, view models)     app/base/ (BasePage, AsyncCubit)
  app/app.dart                          app/app.dart, app_bloc_observer.dart
  app/di/providers.dart                 (DI via RepositoryProvider in app.dart)
  app/router/app_router.dart            app/router/app_router.dart
  app/router/app_shell.dart             app/router/app_shell.dart
  features/posts/presentation/          features/posts/{bloc,view}/
  features/settings/presentation/       features/settings/{cubit,view}/
```

A feature used by one app can live entirely inside it
(`features/<name>/{domain,data,presentation}`); move it to
`packages/feature_<name>` when a second app needs it
([adding-features.md](adding-features.md)).

## Start-up sequence

`initializeAppServices()` (app_foundation) runs these steps; each app's
`bootstrap()` then hands the result to its DI:

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. **Configuration**: `readAppConfig()` validates `--dart-define` values and
   the native flavor. On failure the app shows `ConfigErrorApp` listing every
   problem and stops (fail fast).
3. **Logging** at `LOG_LEVEL`.
4. **Error handlers**: `FlutterError.onError`, `PlatformDispatcher.onError`
   and a neutral `ErrorWidget` in release builds, routed to an
   `ErrorReporter`.
5. **Storage**: open the key-value store and secure store, run
   `StorageMigrator`, open `AppDatabase` (drift runs schema migrations on
   first access).
6. Create the HTTP clients (`ApiClient`, and `GraphQLClient` when
   `GRAPHQL_URL` is set) with the session token and 401 handling.
7. The app runs `runApp(...)` with the services.

## Routing

`go_router` 18 with a `StatefulShellRoute` (one navigation stack per tab),
identical in both apps:

| Path | Screen |
| --- | --- |
| `/` | redirects to `/home` |
| `/home` | Components showcase |
| `/posts` | Posts list |
| `/posts/:id` | Post detail; `:id` must be a positive integer (≤ 9 digits), otherwise redirected to `/not-found` |
| `/settings` | Settings |
| anything else | Not-found page |

Paths and parameter validation live in `AppRoutes` (app_foundation). Deep
links are untrusted input; validate them in `redirect` or the route builder.
Platform deep-link setup (App Links / Universal Links) is not configured
(see [security.md](security.md#deep-links)).

## Networking

### REST

`ApiClient` wraps a Dio instance configured by `HttpSettings`:

- Base URL from `API_BASE_URL`, normalized to end with `/`. Request paths are
  relative (`'posts'`, not `'/posts'`), so a base path like `/v1` is kept.
- Timeouts: connect 15 s, send/receive 30 s.
- Interceptors: `AuthInterceptor` (bearer token, 401 → clear session),
  `LoggingInterceptor` (only with `NETWORK_LOGS=true`, redacted),
  `RetryInterceptor` (`GET`/`HEAD`/`OPTIONS` on connection errors, timeouts
  and 408/429/502/503/504; others only with `RequestExtras.retryable`).
- Methods return `Future<Result<T>>`. HTTP 401 → `UnauthorizedFailure`,
  404 → `NotFoundFailure`, other statuses → `ServerFailure`; decoders that
  throw `FormatException` produce `ParsingFailure`.

### GraphQL

`GraphQLClient` posts `{query, variables, operationName}` over the same Dio
stack, so auth, logging and retries apply unchanged. Queries are retryable;
mutations are not. A response with `errors` becomes `GraphQLFailure`
(messages and `extensions.code`), or `UnauthorizedFailure` when a code is
`UNAUTHENTICATED`. Partial data with errors is treated as a failure.

The posts feature has a `GraphQLPostsDataSource` implementing the same
interface as the REST one; `createPostsRepository` picks it when
`GRAPHQL_URL` is configured. Try it with `config/dev_graphql.json`.

The client is intentionally small: no normalized cache, subscriptions or
generated types. If you need those, adopt a full client (for example
`graphql`/`graphql_flutter` or `ferry` with code generation) inside the data
sources; the repositories and UI do not change.

### Serialization

Hand-written with Dart 3 patterns (`Post.fromJson`,
`GraphQLPostsDataSource._decodePost`). Decoders validate types and throw
`FormatException` on unexpected shapes.

## Storage

| Data | Store | Notes |
| --- | --- | --- |
| Preferences, flags | `KeyValueStore` (`shared_preferences` with cache) | Not encrypted. Synchronous reads after start-up. |
| Tokens, keys, other secrets | `SecureStore` (`flutter_secure_storage`) | Keychain (`first_unlock_this_device`) / Keystore-backed encryption. |
| Structured or larger data, offline caches | `AppDatabase` (drift/SQLite) | Not encrypted by default. Schema and migrations in `packages/database`. |

- **Key-value migrations**: `StorageMigrator` runs ordered steps at start-up
  (v2 removes the old key-value posts cache that the database replaced).
- **Schema migrations**: drift `MigrationStrategy` with snapshots in
  `drift_schemas/` (see [packages/database/README.md](../packages/database/README.md)).
- **Fresh installs**: leftover Keychain secrets from a previous install are
  deleted.
- **Clearing data**: `LocalDataCleaner.clearAll()` wipes secrets, the
  database and preferences (except storage bookkeeping).

## Error handling

| Layer | Mechanism |
| --- | --- |
| Transport and parsing | `ApiClient` / `GraphQLClient` return `Err(AppFailure)` |
| Repositories | return `Result<T>`; decide fallbacks (offline cache on transient failures) |
| State | Riverpod: `getOrThrow()` → `AsyncError`; Bloc: failure states |
| UI | `FailureView` / `describeError` map failure types to localized text |
| Uncaught | `ErrorReporter` (default: logs); plug in crash reporting here |

## Design system and localization

`design_system` builds Material 3 themes from `AppColors.seed` and tokens;
components take localized strings as parameters. The apps import Material
from `package:material_ui` (Material moved out of the framework; mixing it
with `package:flutter/material.dart` creates two unrelated `Theme` types).

`flutter gen-l10n` generates `AppLocalizations` from
`packages/localization/lib/l10n/*.arb` (English template and fallback,
Spanish as a second locale).

## Conventions

- Files `snake_case.dart`; `package:` imports only.
- Constructors use Dart 3.13 syntax (`const new(...)`, `factory json(...)`),
  enforced by `unnecessary_type_name_in_constructor`.
- Riverpod: names end in `Provider` / `Controller`. Bloc: `XBloc` with
  `XEvent`/`XState` sealed hierarchies, `XCubit` for single-action state.
- Storage keys are namespaced: `settings.*`, `session.*`, `storage.*`.
- Generated code (`*.g.dart`, `lib/src/generated/`, `drift_schemas/`) is
  committed and checked by `melos run codegen:check`.
