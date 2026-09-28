# Flutter Monorepo Template

A starter for Flutter applications organized as a
[Melos](https://melos.invertase.dev/) monorepo on
[pub workspaces](https://dart.dev/tools/pub/workspaces). Clone it, rename the
app, point it at your API and start building features on a tested
foundation: configuration per environment, networking, secure storage,
localization, a Material 3 design system, routing, CI and documentation.

It includes an example app with three neutral screens (a component showcase,
a posts list loaded from a placeholder API with offline caching, and
settings). Replace them with your product.

**Who it is for:** teams starting a new Flutter app (or several) who want
sensible defaults, clear package boundaries and CI from day one without
committing to a backend or third-party services.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Repository structure](#repository-structure)
- [Architecture](#architecture)
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
- **State and DI**: Riverpod 3 providers and notifiers, explicit overrides,
  no service locator.
- **Routing**: go_router 18 with per-tab navigation stacks, an adaptive
  bottom bar or rail, validated deep-link parameters and a not-found page.
- **Networking**: Dio-based `ApiClient` returning `Result` values; bearer
  token attachment; retries for idempotent requests only; request logging with
  redaction of tokens, passwords and keys; cancellation; typed failures.
- **Storage**: typed preferences, secure storage for secrets, resumable
  migrations, clean-up of Keychain leftovers after reinstall, a "clear local
  data" flow.
- **Design system**: Material 3 light/dark themes from one seed color,
  spacing/radius/size tokens, buttons, fields, dialogs, loading/empty/error
  views; 48 dp touch targets and contrast checked in tests.
- **Localization**: `flutter gen-l10n`, English plus Spanish as a second
  locale, runtime language switching with device fallback.
- **Reliability**: global error handlers, a pluggable `ErrorReporter`, clear
  loading/empty/error/success states, an offline fallback.
- **Quality**: 126 unit/widget tests, 2 integration tests, strict lints
  (very_good_analysis), a single `melos run validate` gate shared with CI.
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

Run `flutter doctor` to confirm your setup.

## Repository structure

```
.
├── apps/
│   └── app/                  Example application
│       ├── lib/              bootstrap, app shell (config, DI, errors, router), features/
│       ├── config/           dev.json, staging.json, prod.json (build configuration)
│       ├── test/             unit and widget tests
│       ├── integration_test/ end-to-end flows (device required)
│       └── android/ ios/ web/
├── packages/
│   ├── core/                 Result, failures, AppConfig, logging, validators (pure Dart)
│   ├── networking/           ApiClient, interceptors, error mapping (pure Dart)
│   ├── storage/              KeyValueStore, SecureStore, migrations
│   ├── design_system/        tokens, themes, components, responsive layout
│   └── localization/         ARB files and generated AppLocalizations
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
app ──► design_system
    ──► localization
    ──► networking ──► core
    ──► storage ─────► core
    ──► core
```

- Apps depend on packages; packages never depend on apps.
- `core` and `networking` are pure Dart.
- Riverpod and go_router are used only in apps; packages expose plain
  classes and the app wires them together with providers.
- Features live in the app (`lib/features/<name>/{domain,data,presentation}`)
  until another app needs them.

`melos run check:packages` enforces these rules. Details, start-up order and
the reasoning behind each package: [docs/architecture.md](docs/architecture.md).

## Getting started

```sh
git clone https://github.com/Neosoft-Private-Limited/flutter_template.git
cd flutter_template
flutter pub get                  # resolves the whole workspace
dart run melos run validate      # optional: the full quality gate (1–2 minutes)
```

Run the example app on a connected device or emulator:

```sh
cd apps/app
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

The `dev` configuration uses the public placeholder API
[JSONPlaceholder](https://jsonplaceholder.typicode.com) so the posts screen
has data. Tests never call it.

Optional: `dart pub global activate melos 8.9.0` lets you type `melos ...`
instead of `dart run melos ...`. The rest of this README uses the short form.

## Environments and flavors

| Environment | Command (from `apps/app`) |
| --- | --- |
| dev | `flutter run --flavor dev --dart-define-from-file=config/dev.json` |
| staging | `flutter run --flavor staging --dart-define-from-file=config/staging.json` |
| prod | `flutter run --release --flavor prod --dart-define-from-file=config/prod.json` |
| web | `flutter run -d chrome --dart-define-from-file=config/dev.json` (web has no native flavors) |

Always pass both flags; the app shows a configuration error screen if the
flavor and `APP_ENV` disagree. `config/staging.json` and `config/prod.json`
point to placeholder hosts: staging shows network errors until you set a real
URL, and **prod refuses to start** until you do. Builds use the same flags
(`flutter build apk|appbundle|ipa|web ...`). Launch configurations for each
flavor are in `.vscode/launch.json` and `.idea/runConfigurations/`.

## App identifiers and display names

| Flavor | Android ID | iOS bundle ID | Name |
| --- | --- | --- | --- |
| dev | `com.app.flutter_template.dev` | `com.app.flutter-template.dev` | Template Dev |
| staging | `com.app.flutter_template.staging` | `com.app.flutter-template.staging` | Template Staging |
| prod | `com.app.flutter_template` | `com.app.flutter-template` | Flutter Template |

Rename them in one step (commit first, then review the diff):

```sh
dart run tool/rename_app.dart --android-id com.acme.shop --ios-id com.acme.shop --name "Acme Shop" --dry-run
dart run tool/rename_app.dart --android-id com.acme.shop --ios-id com.acme.shop --name "Acme Shop"
```

Then change `appTitle` in `packages/localization/lib/l10n/*.arb` and run
`melos run codegen`. Manual locations:
[docs/environment-configuration.md](docs/environment-configuration.md#identifiers-and-display-names).

## Configuration and secrets

Build configuration lives in `apps/app/config/<env>.json`:

| Key | Required | Values |
| --- | --- | --- |
| `APP_ENV` | yes | `dev`, `staging`, `prod` |
| `API_BASE_URL` | yes | `https` URL (`http` allowed in dev only) |
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

- **Feature**: create `apps/app/lib/features/<name>/` with `domain/`, `data/`
  and `presentation/` as needed, add strings, a route and tests. Walkthrough:
  [docs/adding-features.md](docs/adding-features.md).
- **Package**: `flutter create --template=package packages/<name>`, add
  `resolution: workspace` and the shared SDK constraint, remove the generated
  `analysis_options.yaml`, add tests. Steps:
  [docs/adding-packages.md](docs/adding-packages.md#new-package).
- **Second app**: `flutter create` under `apps/`, join the workspace, reuse
  the bootstrap and flavor setup:
  [docs/adding-packages.md](docs/adding-packages.md#second-application).

New workspace members under `apps/*` and `packages/*` are picked up
automatically; run `melos bootstrap` afterwards.

## Conventions

**State management and DI.** Infrastructure providers live in
`apps/app/lib/app/di/providers.dart` and are overridden in `bootstrap.dart`
(and in tests). Feature providers sit next to their feature. Use
`Notifier`/`AsyncNotifier` for state with actions and `FutureProvider` for
simple loads; mark screen-scoped providers `isAutoDispose: true`. Widgets
render state and forward intents; they contain no business logic.
Riverpod's automatic retry is disabled; retries are explicit.

**Networking.** Call the API only through `ApiClient`. Paths are relative
(`'posts'`). Methods return `Result<T>`; decoders throw `FormatException` on
bad payloads. Only `GET`/`HEAD`/`OPTIONS` are retried automatically.

**Storage.** Preferences and small caches in `KeyValueStore` (not encrypted);
tokens and secrets in `SecureStore`. Namespace keys (`settings.*`,
`cache.*`, `session.*`). Append a `StorageMigration` when persisted data
changes shape.

**Code style.** `package:` imports only, Dart 3.13 constructor syntax
(`const new(...)`), `snake_case` files, public package API in
`lib/<package>.dart`. More in [docs/development.md](docs/development.md#naming-and-file-organization).

## Localization

1. Add the string (with a `description`) to
   `packages/localization/lib/l10n/app_en.arb` and translate it in
   `app_es.arb`.
2. `melos run codegen`, then commit the generated files.
3. Use `context.l10n.yourKey`.

To add a language, add `app_<code>.arb` and an entry in the settings
language list. See [docs/development.md](docs/development.md#localization).

## Code generation

The only generator is `flutter gen-l10n`. Its output is committed so fresh
clones build immediately.

```sh
melos run codegen         # regenerate
melos run codegen:check   # regenerate and fail if the committed files were stale
```

## Quality commands

| Command | Purpose |
| --- | --- |
| `melos run format` / `format:check` | Format / verify formatting |
| `melos run analyze` | Static analysis (infos and warnings fail) for every package and `tool/` |
| `melos run test` | Unit and widget tests in every package |
| `melos run test:coverage` | Tests with `coverage/lcov.info` per package |
| `melos run test:integration` | Integration tests on a device (`DEVICE=<id>`) |
| `melos run check:packages` | Workspace rules (tests present, dependency direction, no cycles) |
| `melos run validate` | All of the above except coverage and integration: the CI gate |
| `melos run clean` | `flutter clean` everywhere |

Full reference: [docs/development.md](docs/development.md#command-reference).
Testing strategy: [docs/testing.md](docs/testing.md).

## CI/CD

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yml` | pull requests, pushes to `main` | Package checks, format, codegen check, analysis, tests with coverage; then Android (debug dev + obfuscated release staging), iOS (debug, no codesign) and web builds. No secrets needed. |
| `integration.yml` | manual, weekly | Integration tests on an Android emulator (API 35). |
| `release.yml` | manual only | Quality gate, then a signed Android App Bundle for `staging` or `prod` using secrets from protected GitHub environments; uploads it as a run artifact. Does not publish to stores. |

Actions are pinned to commit SHAs and updated by Dependabot. Workflows only
have read access to the repository and never push commits. iOS signing and
store uploads are not included (they need your Apple/Google accounts); see
[docs/environment-configuration.md](docs/environment-configuration.md#release-signing).
macOS runners are needed for iOS builds and cost more minutes than Linux.

## Platform support

| Platform | Status | Verified on this template |
| --- | --- | --- |
| Android | Supported | Debug (dev) and release (staging, obfuscated) builds; app run and integration tests on an Android 17 (API 37) emulator |
| iOS | Supported | Debug build without codesigning (dev flavor). Not run on a simulator or device; signing not configured. |
| Web | Builds | Release build compiles. No flavors; secure storage on web is not a security boundary; not tested in a browser. |
| macOS, Windows, Linux | Not included | Add with `flutter create --platforms=macos,windows,linux apps/app` and test the plugins you use. |

## Security checklist

Before shipping, at minimum:

- [ ] Real production API in `config/prod.json`; no secrets in config, code or assets.
- [ ] Tokens stored only via `SessionStore`; sign-out clears local data.
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
| "Invalid build configuration" screen | Pass `--flavor <env> --dart-define-from-file=config/<env>.json` with matching names; for prod, set a real `API_BASE_URL`. |
| `No workspace packages matching ...` or version solving fails | Run `flutter pub get` from the repository root; check that every package has `resolution: workspace` and `sdk: ^3.13.0`. |
| `melos: command not found` | Use `dart run melos ...`, or `dart pub global activate melos 8.9.0` and add `~/.pub-cache/bin` to `PATH`. |
| Android: "Release keystore not configured" warning | Expected without signing secrets; see [release signing](docs/environment-configuration.md#release-signing). |
| Android: `GeneratedPluginRegistrant` cannot find `integration_test` in a release build | Another Flutter command regenerated plugin files mid-build; don't run builds in parallel in the same app. Re-run the build. |
| iOS: `pod install` errors or "Unable to find a target" | `cd apps/app/ios && pod repo update && pod install`; ensure you opened `Runner.xcworkspace`, not the `.xcodeproj`. |
| iOS: "must specify a --flavor" | Expected: there is no default scheme. Use `--flavor dev|staging|prod`. |
| `codegen:check` fails | Run `melos run codegen` and commit `packages/localization/lib/src/generated/`. |
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
- Database layer (add `drift` or similar when a feature needs relational data).
- Crash reporting, analytics, push notifications, payments (optional
  integration points documented).
- Deep-link platform configuration (needs your domain).
- iOS signing, store upload automation, golden tests, iOS/web integration
  tests in CI.
- Desktop platforms.

Possible next steps: an authentication example against a mock server,
golden tests for the design system, and an iOS simulator job for the
integration tests.
