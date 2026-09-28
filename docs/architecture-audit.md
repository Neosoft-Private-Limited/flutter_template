# Architecture audit (September 2026)

This document records the state of the repository **before** modernization, the
decision taken, and the plan that was followed. It is a historical record; the
current architecture is described in [architecture.md](architecture.md).

- Audit date: 2026-09-28
- Audited revision: `0413ed2` (`main`) plus 69 uncommitted working-tree changes
  (an earlier, unfinished migration attempt). Those changes were preserved in
  `git stash` (`stash@{0}`, "pre-modernization WIP backup (2026-09-28)") before
  any modernization work started.
- Target toolchain (installed on the audit machine): Flutter 3.47.5 (stable),
  Dart 3.13.4, Melos 8.9.0, Xcode 27.0, CocoaPods 1.17.0, Android SDK 36/37,
  OpenJDK 17.

## 1. Current architecture and package map

The repository was a Melos monorepo loosely following hexagonal
("ports and adapters") architecture.

| Package (path) | Role | Depends on |
| --- | --- | --- |
| `app` | Flutter app: splash screen, flavors (`dev`/`qa`/`prod`), DI bootstrap | every package below |
| `core/shared` | error types, `AppError`, `User`, `Validator`, layer transformers | – |
| `core/domain` | `BaseUseCase`, `Params`, `LoginUseCase`, `UserRepository` contract, `dartz` | shared, dependency_injection |
| `core/data` | `UserRepositoryImpl` (all methods `throw UnimplementedError()`), `DatabasePort`, `NetworkPort` | domain, shared, dependency_injection |
| `dependency-injection` | `DependencyConfigurator` interface over `get_it` | get_it, injectable |
| `infrastructure/database-floor` | Floor database with a `user` table; persistence adapter methods are empty TODOs | data |
| `infrastructure/network-retrofit` | Dio + Retrofit client with **no endpoints**; network adapter is an empty TODO | data |
| `localisation` | two competing localization setups (`intl_utils` generated `Strings` and a new `gen_l10n` config whose output was never generated) | flutter_localizations, intl |
| `services` | global `navigatorKey` / `appKey` | – |
| `statemanagement-core` | `CoreBasePageState` (Scaffold template with lifecycle observer) | – |
| `statemanagement-riverpod` | `BasePage`/`BaseViewModel` over `ChangeNotifierProvider` | statemanagement-core, flutter_riverpod 2 |
| `statemanagement-bloc` | parallel Bloc variant, **not used by the app** | statemanagement-core, bloc |
| `themes` | `ThemeBuilder`/`ThemeManager` (provider + rxdart + shared_preferences + get_it) | dependency_injection |

Dependency direction was mostly inward, but DI (`get_it`/`injectable`) leaked
into every layer, `domain` depended on the DI package, and `themes` resolved
services through the global `GetIt.I` service locator.

## 2. Functionality inventory

| Area | What existed | Working? |
| --- | --- | --- |
| Startup | `startApp()` configures six DI modules then `runApp` | Needs generated DI files; failed without codegen |
| Screens | One splash screen with a "Test" button that prints the base URL | Yes (at HEAD) |
| Routing | `onGenerateRoute` switch with one route; unknown routes render an empty `Container` | Minimal |
| Flavors | `dev`/`qa`/`prod` Dart entrypoints, Android product flavors, iOS schemes (`qa` build configurations missing in the Xcode project) | Partially |
| Config/secrets | `FlavorValues` + git-ignored `app_secrets.dart` compiled into the binary; CI decoded a base64 secret into Dart source | Works, but secrets end up in the app binary |
| Networking | Dio instance with `PrettyDioLogger` logging **all headers and bodies** | No endpoints |
| Database | Floor `AppDatabase` with a `user` table and a migration that references a column never declared on the entity | Not wired to any feature |
| Domain | `LoginUseCase` + validation of email/password | Repository unimplemented |
| Theming | light/dark/system with persistence, status-bar coloring | Yes, but via global service locator |
| Localization | `appName` string | Generated file referenced by `strings.dart` did not exist |
| Responsive | `responsive_framework` breakpoints | Yes |
| Tests | Placeholder tests referencing a deleted `Awesome` class; app test is the default counter test | **No meaningful tests** |
| CI | PR workflow: bootstrap, codegen, analyze, test, Android/iOS debug builds; needed the `APP_SECRETS` secret even for PRs | Broken against current toolchain |
| CD | On every push to `main`: build signed APK, create GitHub release, **bump version and push a commit to `main`** using `contents: write` | Risky; see security findings |
| Scripts | run/build wrappers, iOS `main.dart` rewriting hack, version bump/commit, git hooks | Partly obsolete |

## 3. Dependency and compatibility audit

| Dependency | State at audit | Assessment |
| --- | --- | --- |
| `floor` / `floor_generator` 1.5.0 | Last release 2023; generator pins `analyzer ^6` → requires the `_macros` SDK package that Dart 3.13 no longer ships | **Incompatible, effectively abandoned**. Blocks dependency resolution for the whole workspace. |
| `dartz` 0.10.1 | Last release 2021, SDK constraint `<3.0.0` | Abandoned; replace with Dart 3 sealed classes |
| `dio` 4.0.6 (HEAD) | Affected by GHSA-9324-jv53-9cc8 and GHSA-jwpw-q68h-r678 | Upgrade to 5.x |
| `retrofit` / `retrofit_generator` | Maintained, but the service had zero endpoints | Unused code generation |
| `get_it` / `injectable` | Maintained; used as a global service locator across layers | Replace with Riverpod providers (one mechanism for DI and state) |
| `flutter_riverpod` 2.x | Riverpod 3.4 current; `ChangeNotifierProvider` is now legacy | Upgrade and use `Notifier`/`AsyncNotifier` |
| `bloc` / `flutter_bloc` | Maintained, but the Bloc module was not used | Remove; one state-management approach |
| `provider`, `rxdart` | Only used inside `themes` in addition to Riverpod | Remove (duplicate state mechanisms) |
| `responsive_framework` 1.5.1 | Last release 2024-08 | Replace with a small breakpoint helper |
| `intl_utils` generated code | Superseded by Flutter's built-in `gen-l10n` | Remove |
| `pretty_dio_logger` | Logs tokens and bodies | Replace with a redacting interceptor |
| `package:flutter/material.dart` | Material has moved to the `material_ui` package (go_router 18 already depends on it) | Adopt `material_ui` consistently |
| Android: AGP 7.1.2, Gradle 7.4, Kotlin 1.6.10, Java 8, imperative `apply from: flutter.gradle` | Flutter 3.47 refuses the imperative plugin application | **Build fails**; regenerate platform projects |
| iOS: deployment target 9.0, absolute `/Users/apple/...` file references, stray `Runner copy-Info.plist` files | Unsupported target; project not portable | Regenerate |
| Web: pre-2023 `index.html` bootstrap | Outdated loader | Regenerate |

## 4. Technical debt and security findings

Security

1. **Secrets compiled into the app.** `app_secrets.dart` puts third-party API
   keys in Dart source, which ends up in the binary. Anything shipped in a
   mobile/web client is extractable; the template must say so and keep real
   secrets on a backend.
2. **Sensitive logging.** `PrettyDioLogger` logged request/response headers
   and bodies (authorization headers, passwords, tokens) in every flavor.
3. **CI requires secrets for pull requests** (`APP_SECRETS`), which fails for
   forks and encourages widening secret exposure.
4. **CD pushes to `main`** with `contents: write` on every merge, using
   `--no-verify`, and publishes a release as a side effect of merging.
5. **Vulnerable dependency** (`dio` 4.0.6) at HEAD.
6. Third-party GitHub Actions pinned only by major tag; `timheuer/base64-to-file`
   receives the keystore.
7. `clearPreferences()` wiped *all* shared preferences; no separation of
   secure vs. non-secure data; no logout clean-up concept.

Technical debt

- Two localization systems, two state-management modules, three DI-related
  packages, most of them placeholders.
- Stub implementations (`UnimplementedError`, empty adapters) presented as
  architecture.
- `CoreBasePageState` forced every screen into an inheritance hierarchy
  (`BasePage → BasePageState → BaseStatefulPage → AppBasePageState`) and
  called `onModelReady` on every rebuild.
- Unknown routes rendered a blank screen; no deep-link validation.
- `lib/main.dart` rewritten by `sed` during iOS builds (obsolete workaround).
- Generated DI files were git-ignored but required to compile, so a fresh clone
  did not build without running codegen first.
- Root `.gitignore` ignored every `pubspec.lock`, including the app's.
- `sonar-project.properties` and README badges reference a different
  repository (`NeoSOFT-Technologies/mobile-flutter`).

## 5. Baseline results (before any change)

All commands were run on the audit machine; nothing here is inferred.

| Check | Working tree (uncommitted WIP) | Committed HEAD `0413ed2` (temporary worktree) |
| --- | --- | --- |
| Dependency resolution | **Fails** (`flutter pub get` exit 69: `floor_generator` → `analyzer ^6` → `_macros` missing from SDK) | `app` resolves with old versions; pub reports 2 security advisories on `dio 4.0.6` |
| Melos | Cannot start (resolution failure) | Not attempted (Melos 2.x config) |
| Formatting | Not runnable | Not run |
| Static analysis | Not runnable | `app` only: 16 issues (3 × `deprecated_member_use`, plus infos) |
| Code generation | Not runnable | `build_runner` succeeded for `app` |
| Tests | Not runnable | **Fail**: `app/test/widget_test.dart` fails to load (missing generated DI files in other packages; the test is the default counter test anyway) |
| Android build (`apk --flavor dev --debug`) | Not runnable | **Fails**: "applying Flutter's app_plugin_loader Gradle plugin imperatively ... is not possible anymore" |
| iOS / web builds | Not runnable | Not attempted (Android failure already blocks the documented CI path) |

Every failure above is pre-existing.

## 6. Migrate or rebuild?

**Decision: rebuild the workspace in place (on branch `modernize/flutter-3.47`),
deliberately migrating the pieces that have value.**

Reasoning:

- Almost none of the Dart code is exercised or tested: data, network and
  database adapters are stubs; the domain layer's only use case calls an
  unimplemented repository. Migrating it would mean upgrading placeholders.
- The platform projects cannot be upgraded incrementally in a meaningful way
  (Gradle DSL change, iOS 9 target, absolute paths). Regenerating them with
  `flutter create` and re-applying flavors is cheaper and less error-prone.
- The most expensive dependency (`floor`) is incompatible with the SDK and
  unmaintained, which forces a storage redesign regardless.
- Git history and `stash@{0}` preserve every line of the old code.

What is retained (as concepts or code):

| Retained | Where it lives now |
| --- | --- |
| Melos monorepo, modular packages, inward dependency direction | root `pubspec.yaml`, `packages/*` |
| Flavors with distinct IDs (`dev`, `qa` → `staging`, `prod`) | Android product flavors, iOS schemes/xcconfigs, `config/*.json` |
| Error taxonomy (`ErrorType`, `NetworkError`/`DatabaseError` → `AppError`) | sealed `AppFailure` hierarchy in `packages/core` |
| `Validator` (email/empty/password length) | `packages/core` validators, now returning typed error codes |
| Theme mode light/dark/system with persistence | `design_system` + app `ThemeModeController` |
| Localized strings from the new ARB file | `packages/localization` |
| Timeouts, base-URL configuration, Dio | `packages/networking` |
| Status/navigation bar contrast logic | replaced by Material 3 `AppBarTheme` system overlay handling |
| CI structure (analyze, test, Android and iOS builds) | `.github/workflows/ci.yml` |
| Keystore-from-secrets signing, version from `pubspec.yaml` | `.github/workflows/release.yml` (manual, protected) |
| Apache-2.0 license | unchanged |

What is removed and why (replacement in brackets):

- `floor` database module — incompatible and unmaintained; no feature used it
  [typed key-value storage + secure storage; `drift` documented as the
  recommended path when relational data is needed].
- `dependency-injection`, `get_it`, `injectable` [Riverpod providers with
  explicit overrides].
- `statemanagement-*` base-page hierarchy, `bloc` module [Riverpod
  `Notifier`/`AsyncNotifier` + plain `ConsumerWidget`s].
- `dartz` [Dart 3 sealed `Result<T>`].
- `retrofit` (no endpoints) [hand-written, typed API classes over one `ApiClient`].
- `services` global keys [go_router].
- `themes` (provider/rxdart/get_it) [`design_system` package].
- `responsive_framework` [`Breakpoints` helper in `design_system`].
- `intl_utils` output [`flutter gen-l10n`].
- `app_secrets.dart` [non-secret build configuration via
  `--dart-define-from-file`; secrets stay server-side].
- Obsolete scripts (`build.sh` `main.dart` rewriting, `device-preview.sh` for a
  package that is not a dependency, `commit-version.sh` pushing to `main`)
  [Melos scripts, manual release workflow].

## 7. Target architecture

```
apps/app                  Flutter application (composition root, features, routing)
packages/core             pure Dart: Result, AppFailure, AppConfig, logging + redaction, validators
packages/networking       pure Dart: Dio-based ApiClient, interceptors, error mapping
packages/storage          Flutter: KeyValueStore, SecureStore, schema migrations
packages/design_system    Flutter: tokens, light/dark themes, reusable components, breakpoints
packages/localization     Flutter: ARB files and generated AppLocalizations
```

Dependency direction: `app → {design_system, localization, networking,
storage} → core`. Packages never depend on the app or on Riverpod; the app wires
them together with providers. Features live inside the app
(`lib/features/<feature>/{data,domain,presentation}`) until a second app needs
them, at which point a feature is extracted into `packages/`.

Technology choices: Riverpod 3 (state + DI), go_router 18 (routing, deep
links), Dio 5 (HTTP), hand-written JSON parsing with Dart 3 patterns (no
serialization code generation), shared_preferences + flutter_secure_storage
(storage), `package:logging` (logging), `flutter gen-l10n` (localization),
`material_ui` (Material 3), very_good_analysis (lints), mocktail (test doubles).

## 8. Prioritized implementation plan

1. Workspace: root `pubspec.yaml` with pub workspace globs and Melos 8 config;
   shared analysis options; lockfile committed.
2. `core`, `networking`, `storage`, `localization`, `design_system` packages
   with unit/widget tests.
3. Regenerate the app platform projects; re-apply flavors (Android Kotlin DSL,
   iOS build configurations and schemes).
4. App: bootstrap, config validation, error handling, routing, theme/locale
   settings, example API feature with loading/empty/error/success states and
   offline cache, design-system showcase with form validation.
5. Tests: unit, widget, integration (`integration_test`).
6. Tooling: Melos scripts (`validate` et al.), VS Code/IntelliJ launch configs,
   rename script.
7. CI (PR quality gate, builds) and a manual, protected release workflow.
8. Security review, documentation, README last, final validation.
