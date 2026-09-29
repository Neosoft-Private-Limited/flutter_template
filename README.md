# Flutter Monorepo Template

A starter for Flutter applications organized as a
[Melos](https://melos.invertase.dev/) monorepo on
[pub workspaces](https://dart.dev/tools/pub/workspaces). Clone it, pick
Riverpod or Bloc, rename the app, point it at your API and start building
features on a tested foundation: configuration per environment, REST and
GraphQL networking, a SQLite database, secure storage, localization, a
Material 3 design system, routing, CI and documentation.

It ships the same example app twice, once with **Riverpod** (`apps/app`) and
once with **Bloc** (`apps/app_bloc`), both built on the same shared packages.
Each has three neutral screens (a component showcase, a posts list loaded
from a placeholder API with an offline SQLite cache, and settings). Keep the
app that matches your team's choice and replace the screens with your
product.

**Who it is for:** teams starting a new Flutter app (or several) who want
sensible defaults, clear package boundaries and CI from day one without
committing to a backend or third-party services.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Repository structure](#repository-structure)
- [Architecture](#architecture)
- [Choosing Riverpod or Bloc](#choosing-riverpod-or-bloc)
- [Getting started](#getting-started)
- [Environments and flavors](#environments-and-flavors)
- [App identifiers and display names](#app-identifiers-and-display-names)
- [Configuration and secrets](#configuration-and-secrets)
- [Adding packages, features and apps](#adding-packages-features-and-apps)
- [Conventions](#conventions)
- [Localization](#localization)
- [Code generation](#code-generation)
- [Quality commands](#quality-commands)
- [CI/CD](#cicd)
- [Platform support](#platform-support)
- [Security checklist](#security-checklist)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Known limitations and roadmap](#known-limitations-and-roadmap)

## Features

- **Environments**: `dev`, `staging` and `prod` flavors with distinct
  application IDs and names on Android and iOS; typed, validated build
  configuration; production builds refuse to start with placeholder settings.
- **Architecture**: small packages with one responsibility, dependencies
  pointing inward, checked automatically (no cycles, no framework leaks).
  Shared packages never depend on a state-management library.
- **State and DI, your choice**: Riverpod 3 (providers, notifiers, explicit
  overrides) or flutter_bloc 9 (blocs, cubits, `RepositoryProvider`). No
  service locator.
- **MVVM pages**: every screen extends `BasePage` (or `BaseAsyncPage`) and
  pairs with a view model; the base handles the scaffold, lifecycle hooks
  and loading/error states, so a data screen implements only its success
  view.
- **Routing**: go_router 18 with per-tab navigation stacks, an adaptive
  bottom bar or rail, validated deep-link parameters and a not-found page.
- **Networking**: Dio-based `ApiClient` (REST) and `GraphQLClient` sharing
  one policy: bearer token, retries for idempotent requests only, redacted
  logging, cancellation, typed failures. The example feature switches
  between REST and GraphQL with one config value.
- **Storage**: drift (SQLite) database with schema migrations, typed
  preferences, secure storage for secrets, key-value migrations, clean-up
  of Keychain leftovers after reinstall, a "clear local data" flow.
- **Design system**: Material 3 light/dark themes from one seed color,
  spacing/radius/size tokens, buttons, fields, dialogs, loading/empty/error
  views; 48 dp touch targets and contrast checked in tests.
- **Localization**: `flutter gen-l10n`, English plus Spanish as a second
  locale, runtime language switching with device fallback.
- **Reliability**: global error handlers, a pluggable `ErrorReporter`, clear
  loading/empty/error/success states, an offline fallback.
- **Quality**: 197 unit/widget tests, 4 integration tests, enterprise-grade
  lints (very_good_analysis plus extra rules, safety diagnostics as errors,
  un-ignorable correctness rules, documented public APIs), a single
  `melos run validate` gate shared with CI.
- **Tooling**: rename script, VS Code and IntelliJ launch configurations,
  Dependabot, manual release workflow.

## Requirements

| Tool | Version | Notes |
| --- | --- | --- |
| Flutter | 3.47.5 (stable) | Minimum 3.47.0 (`material_ui` requires it); CI pins 3.47.5 |
| Dart | 3.13.4 (bundled) | SDK constraint `^3.13.0` |
| Melos | 8.9.0 | Workspace dev dependency; no global install needed |
| Java | 17 | Android builds (AGP 9.1, Gradle 9.3.1) |
| Xcode | 27 (tested) | iOS builds; CocoaPods 1.17 |
| Android | minSdk 24 (Flutter default), target/compile SDK 36 | |
| iOS | 15.0+ | |
| Network access to GitHub at build time | | `sqlite3` downloads prebuilt, checksum-verified SQLite binaries through its build hook |

Run `flutter doctor` to confirm your setup.

## Repository structure

```
.
├── apps/
│   ├── app/                  Example app with Riverpod
│   └── app_bloc/             Same example app with Bloc
│       ├── lib/              bootstrap, app (DI, router), features/<name>/<state + view>
│       ├── config/           dev.json, dev_graphql.json, staging.json, prod.json
│       ├── test/             unit, bloc and widget tests
│       ├── integration_test/ end-to-end flows (device required)
│       └── android/ ios/ web/
├── packages/
│   ├── core/                 Result, failures, AppConfig, logging, validators (pure Dart)
│   ├── networking/           ApiClient (REST), GraphQLClient, interceptors (pure Dart)
│   ├── storage/              KeyValueStore, SecureStore, migrations
│   ├── database/             drift (SQLite): schema, DAOs, schema migrations
│   ├── design_system/        tokens, themes, components, responsive layout
│   ├── localization/         ARB files and generated AppLocalizations
│   ├── app_foundation/       start-up, config, errors, session, settings, shared screens
│   └── feature_posts/        example feature: domain, REST/GraphQL data, cache, widgets
├── tool/                     workspace scripts (checks, rename, integration runner)
├── docs/                     guides (see below)
├── .github/                  CI, integration and release workflows, templates
├── analysis_options.yaml     shared lint rules for every package
└── pubspec.yaml              workspace members + Melos configuration
```

Guides: [architecture](docs/architecture.md) ·
[development](docs/development.md) ·
[environment configuration](docs/environment-configuration.md) ·
[testing](docs/testing.md) · [adding features](docs/adding-features.md) ·
[adding packages and apps](docs/adding-packages.md) ·
[security](docs/security.md) ·
[modernization audit](docs/architecture-audit.md)

## Architecture

```
apps (Riverpod / Bloc: state, DI, routing)
  └─► feature_posts (domain, data, stateless widgets)
        └─► app_foundation (start-up, config, errors, settings, shared screens)
              └─► design_system · localization · networking · storage · database
                                                   └─► core
```

- Apps depend on packages; packages never depend on apps.
- `core` and `networking` are pure Dart.
- Riverpod, Bloc and go_router are used only in apps.
- A feature used by one app lives in the app; a feature shared by apps is a
  `feature_<name>` package with everything except state management and
  routing.

**Why posts code is in two places.** `packages/feature_posts` holds the
parts of the posts feature that both example apps share (model, REST/GraphQL
data sources, offline cache, repository, stateless widgets);
`apps/<app>/lib/features/posts/` holds only that app's pages and view
models. It is a package only because two apps use it. Once you keep a single
app, move `packages/feature_posts/lib/src` into
`apps/<app>/lib/features/posts/` (and its tests), then delete the package:
new features go straight into the app (see
[docs/adding-features.md](docs/adding-features.md)).

`melos run check:packages` enforces these rules. Details, start-up order and
the reasoning behind each package: [docs/architecture.md](docs/architecture.md).

## Choosing Riverpod or Bloc

Both apps have identical screens, routes, flavors and behaviour, and use the
same packages. Only the presentation layer differs:

| | `apps/app` (Riverpod) | `apps/app_bloc` (Bloc) |
| --- | --- | --- |
| DI | Providers + `ProviderScope` overrides | `RepositoryProvider`s |
| Pages | `BasePage` / `BaseAsyncPage` + `viewModelProvider` | `BasePage` / `BaseAsyncPage` + `createViewModel` |
| View models | `Notifier`, `AsyncViewModel` | `Bloc`, `Cubit`, `AsyncCubit` |
| Theme/locale | `Notifier` providers | `ThemeCubit`, `LocaleCubit` |
| Tests | Widget tests with provider overrides | `bloc_test` + widget tests |

To keep only one:

```sh
git rm -r apps/app_bloc      # keep Riverpod
# or: git rm -r apps/app     # keep Bloc
```

Then remove the deleted app from the build loops in
`.github/workflows/ci.yml`, the `app` choices in `release.yml`, and its
entries in `.vscode/launch.json` and `.idea/runConfigurations/`. Run
`flutter pub get` and `melos run validate`. More in
[docs/architecture.md](docs/architecture.md#riverpod-or-bloc).

## Getting started

```sh
git clone https://github.com/Neosoft-Private-Limited/flutter_template.git
cd flutter_template
flutter pub get                  # resolves the whole workspace
dart run melos run validate      # optional: the full quality gate (1–2 minutes)
```

Run an example app on a connected device or emulator:

```sh
cd apps/app                      # or apps/app_bloc
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

The `dev` configuration uses the public placeholder API
[JSONPlaceholder](https://jsonplaceholder.typicode.com) so the posts screen
has data. `config/dev_graphql.json` fetches the same data over GraphQL from
[GraphQLZero](https://graphqlzero.almansi.me). Tests never call either.

Optional: `dart pub global activate melos 8.9.0` lets you type `melos ...`
instead of `dart run melos ...`. The rest of this README uses the short form.

## Environments and flavors

| Environment | Command (from `apps/app` or `apps/app_bloc`) |
| --- | --- |
| dev | `flutter run --flavor dev --dart-define-from-file=config/dev.json` |
| dev (GraphQL) | `flutter run --flavor dev --dart-define-from-file=config/dev_graphql.json` |
| staging | `flutter run --flavor staging --dart-define-from-file=config/staging.json` |
| prod | `flutter run --release --flavor prod --dart-define-from-file=config/prod.json` |
| web | `flutter run -d chrome --dart-define-from-file=config/dev.json` (web has no native flavors) |

Always pass both flags; the app shows a configuration error screen if the
flavor and `APP_ENV` disagree. `config/staging.json` and `config/prod.json`
point to placeholder hosts: staging shows network errors until you set a real
URL, and **prod refuses to start** until you do. Builds use the same flags
(`flutter build apk|appbundle|ipa|web ...`). Launch configurations for each
app and flavor are in `.vscode/launch.json` and `.idea/runConfigurations/`.

## App identifiers and display names

| Flavor | `apps/app` Android / iOS ID | `apps/app_bloc` Android / iOS ID | Names |
| --- | --- | --- | --- |
| dev | `com.app.flutter_template.dev` / `com.app.flutter-template.dev` | `com.app.flutter_template.bloc.dev` / `com.app.flutter-template.bloc.dev` | Template Dev · Bloc Template Dev |
| staging | `com.app.flutter_template.staging` / `com.app.flutter-template.staging` | `com.app.flutter_template.bloc.staging` / `com.app.flutter-template.bloc.staging` | Template Staging · Bloc Template Staging |
| prod | `com.app.flutter_template` / `com.app.flutter-template` | `com.app.flutter_template.bloc` / `com.app.flutter-template.bloc` | Flutter Template · Bloc Template |

Rename an app in one step (commit first, then review the diff):

```sh
dart run tool/rename_app.dart --app-dir apps/app --android-id com.acme.shop --ios-id com.acme.shop --name "Acme Shop" --dry-run
dart run tool/rename_app.dart --app-dir apps/app --android-id com.acme.shop --ios-id com.acme.shop --name "Acme Shop"
```

Then change `appTitle` in `packages/localization/lib/l10n/*.arb` and run
`melos run codegen`. Manual locations:
[docs/environment-configuration.md](docs/environment-configuration.md#identifiers-and-display-names).

## Configuration and secrets

Build configuration lives in `apps/<app>/config/<env>.json`:

| Key | Required | Values |
| --- | --- | --- |
| `APP_ENV` | yes | `dev`, `staging`, `prod` |
| `API_BASE_URL` | yes | `https` URL (`http` allowed in dev only) |
| `GRAPHQL_URL` | no | `https` URL; when set, the posts feature uses GraphQL |
| `LOG_LEVEL` | no (`info`) | `debug`, `info`, `warning`, `error`, `off` |
| `NETWORK_LOGS` | no (`false`) | `true`, `false` |

For machine-specific values, create a git-ignored `config/<env>.local.json`
and pass it instead.

**These values are compiled into the app and are readable by anyone who has
it. Do not put secrets in them.** Keep API secrets on your backend; store
runtime tokens with `SessionStore` (secure storage). Android release signing
reads `ANDROID_KEYSTORE_*` environment variables or a git-ignored
`android/key.properties`. Full details, including how to add a key and set up
signing: [docs/environment-configuration.md](docs/environment-configuration.md).

## Adding packages, features and apps

- **Feature**: add `features/<name>/` to the app (domain, data, presentation
  as needed), strings, a route and tests; move it to a `feature_<name>`
  package when another app needs it. Walkthrough with Riverpod and Bloc
  variants: [docs/adding-features.md](docs/adding-features.md).
- **Database table**: edit `packages/database`, bump the schema version, run
  `build_runner` and `drift_dev make-migrations`:
  [packages/database/README.md](packages/database/README.md).
- **Package**: `flutter create --template=package packages/<name>`, add
  `resolution: workspace` and the shared SDK constraint, remove the generated
  `analysis_options.yaml`, add tests:
  [docs/adding-packages.md](docs/adding-packages.md#new-package).
- **Another app**: copy an app's platform folders, run the rename tool and
  reuse `app_foundation`:
  [docs/adding-packages.md](docs/adding-packages.md#second-application).

New workspace members under `apps/*` and `packages/*` are picked up
automatically; run `melos bootstrap` afterwards.

## Conventions

**State management and DI.** Infrastructure is created once by
`initializeAppServices()` (app_foundation) and exposed by each app: Riverpod
overrides (`apps/app/lib/app/di/providers.dart`) or `RepositoryProvider`s
(`apps/app_bloc/lib/app/app.dart`). Screens follow MVVM: a page extends
`BasePage`/`BaseAsyncPage` (`lib/app/base/`) and talks to its view model
(`Notifier`/`AsyncViewModel` or `Bloc`/`Cubit`/`AsyncCubit`); the repository
is the model. Pages render state and forward intents and contain no
business logic. See
[docs/architecture.md](docs/architecture.md#pages-and-view-models-mvvm).

**Networking.** Call APIs only through `ApiClient` or `GraphQLClient`. REST
paths are relative (`'posts'`). Methods return `Result<T>`; decoders throw
`FormatException` on bad payloads. Only `GET`/`HEAD`/`OPTIONS` and GraphQL
queries are retried automatically.

**Storage.** Structured data and caches in the drift database; preferences
in `KeyValueStore`; tokens and secrets in `SecureStore`. Neither the database
nor preferences are encrypted. Namespace keys (`settings.*`, `session.*`).

**Code style.** `package:` imports only, Dart 3.13 constructor syntax
(`const new(...)`), `snake_case` files, public package API in
`lib/<package>.dart`. More in [docs/development.md](docs/development.md#naming-and-file-organization).

## Localization

1. Add the string (with a `description`) to
   `packages/localization/lib/l10n/app_en.arb` and translate it in
   `app_es.arb`.
2. `melos run codegen`, then commit the generated files.
3. Use `context.l10n.yourKey`.

To add a language, add `app_<code>.arb` and an entry in the language list
of `SettingsView` (app_foundation). See
[docs/development.md](docs/development.md#localization).

## Code generation

| Generator | Where | Output |
| --- | --- | --- |
| `flutter gen-l10n` | `packages/localization` | `lib/src/generated/` |
| `build_runner` + drift | `packages/database` | `*.g.dart`, schema snapshots in `drift_schemas/` |

Generated files are committed so fresh clones build immediately.

```sh
melos run codegen         # regenerate everything
melos run codegen:check   # regenerate and fail if the committed files were stale
```

## Quality commands

| Command | Purpose |
| --- | --- |
| `melos run format` / `format:check` | Format / verify formatting |
| `melos run analyze` | Static analysis (infos and warnings fail) for every package and `tool/` |
| `melos run test` | Unit, bloc and widget tests in every package |
| `melos run test:coverage` | Tests with `coverage/lcov.info` per package |
| `melos run test:integration` | Integration tests of every app on a device (`DEVICE=<id>`, `APP=apps/<name>`) |
| `melos run check:packages` | Workspace rules (tests present, dependency direction, no cycles) |
| `melos run validate` | All of the above except coverage and integration: the CI gate |
| `melos run clean` | `flutter clean` everywhere |

Full reference: [docs/development.md](docs/development.md#command-reference).
Testing strategy: [docs/testing.md](docs/testing.md).

## CI/CD

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yml` | pull requests, pushes to `main` | Package checks, format, codegen check, analysis, tests with coverage; then, for both apps, Android (debug dev + obfuscated release staging), iOS (debug, no codesign) and web builds. No secrets needed. |
| `integration.yml` | manual, weekly | Integration tests of both apps on an Android emulator (API 35). |
| `release.yml` | manual only | Choose app and flavor; quality gate, then a signed Android App Bundle using secrets from protected GitHub environments; uploads it as a run artifact. Does not publish to stores. |

Actions are pinned to commit SHAs and updated by Dependabot. Workflows only
have read access to the repository and never push commits. iOS signing and
store uploads are not included (they need your Apple/Google accounts); see
[docs/environment-configuration.md](docs/environment-configuration.md#release-signing).
macOS runners are needed for iOS builds and cost more minutes than Linux.

## Platform support

| Platform | Status | Verified on this template (both apps unless noted) |
| --- | --- | --- |
| Android | Supported | Debug (dev) and release (staging, obfuscated) builds; integration tests (including on-device SQLite) on an Android emulator |
| iOS | Supported | Debug builds without codesigning (dev flavor). Not run on a simulator or device; signing not configured. |
| Web | Builds | Release builds compile and include drift's `sqlite3.wasm`/`drift_worker.js`. No flavors; not tested in a browser; secure storage on web is not a security boundary. |
| macOS, Windows, Linux | Not included | Add with `flutter create --platforms=macos,windows,linux apps/<app>` and test the plugins you use. |

## Security checklist

Before shipping, at minimum:

- [ ] Real production API in `config/prod.json`; no secrets in config, code or assets.
- [ ] Tokens stored only via `SessionStore`; sign-out clears local data.
- [ ] Nothing sensitive in the database or preferences (neither is encrypted), or database encryption enabled.
- [ ] Sensitive field names added to `Redactor.sensitiveKeys`.
- [ ] Release keystore and Apple credentials kept outside the repo; `production` environment protected.
- [ ] Deep-link domains verified (App Links / Universal Links) and parameters validated.
- [ ] Permissions and privacy declarations reviewed for every plugin you add.
- [ ] Branch protection requires CI; Dependabot PRs reviewed.

The complete list and what the template already does:
[docs/security.md](docs/security.md). Report vulnerabilities via
[SECURITY.md](SECURITY.md).

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| "Invalid build configuration" screen | Pass `--flavor <env> --dart-define-from-file=config/<env>.json` with matching names; for prod, set a real `API_BASE_URL` (and `GRAPHQL_URL` if used). |
| `No workspace packages matching ...` or version solving fails | Run `flutter pub get` from the repository root; check that every package has `resolution: workspace` and `sdk: ^3.13.0`. |
| `melos: command not found` | Use `dart run melos ...`, or `dart pub global activate melos 8.9.0` and add `~/.pub-cache/bin` to `PATH`. |
| Build fails while "Running build hooks" / downloading sqlite3 | The build needs network access to GitHub releases; behind a proxy, mirror the binaries and set the sqlite3 `url_pattern` hook option (see `packages/database/README.md`). |
| build_runner warns "These options have been removed and were ignored: --delete-conflicting-outputs" | build_runner 2.16 removed the flag; run `dart run build_runner build`. |
| Android: "Release keystore not configured" warning | Expected without signing secrets; see [release signing](docs/environment-configuration.md#release-signing). |
| Android: `GeneratedPluginRegistrant` cannot find `integration_test` in a release build | Another Flutter command regenerated plugin files mid-build; don't run builds in parallel in the same workspace. Re-run the build. |
| iOS: `pod install` errors or "Unable to find a target" | `cd apps/<app>/ios && pod repo update && pod install`; ensure you opened `Runner.xcworkspace`, not the `.xcodeproj`. |
| iOS: "must specify a --flavor" | Expected: there is no default scheme. Use `--flavor dev|staging|prod`. |
| Web: database errors at start-up | `web/sqlite3.wasm` and `web/drift_worker.js` must exist and match the `sqlite3`/`drift` versions (see `packages/database/README.md`). |
| `codegen:check` fails | Run `melos run codegen` and commit the regenerated files. |
| Posts screen shows an error in staging | `config/staging.json` uses a placeholder host; set your API. |

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). In short: one change per pull
request, tests for changed behaviour, `melos run validate` before pushing.

## License

[Apache License 2.0](LICENSE). The license file's appendix still contains the
`[yyyy] [name of copyright owner]` placeholder; maintainers should fill it in.

## Known limitations and roadmap

Not included (by design or pending decisions):

- Authentication flow and token refresh (backend-specific; `SessionStore` and
  `AuthInterceptor` are the extension points).
- GraphQL normalized cache, subscriptions and generated types (the client is
  intentionally minimal; adopt `graphql`/`ferry` inside data sources if
  needed).
- Database encryption (available through the sqlite3 hook options).
- Crash reporting, analytics, push notifications, payments (optional
  integration points documented).
- Deep-link platform configuration (needs your domain).
- iOS signing, store upload automation, golden tests, iOS/web integration
  tests in CI.
- Desktop platforms.

Possible next steps: an authentication example against a mock server,
golden tests for the design system, and an iOS simulator job for the
integration tests.
