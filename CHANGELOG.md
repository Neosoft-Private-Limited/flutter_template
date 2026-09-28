# Changelog

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
