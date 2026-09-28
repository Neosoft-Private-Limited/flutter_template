# Adding a package or an app

## Before adding a package

Add a package only when code has a clear responsibility **and** more than one
consumer (or needs to be isolated from Flutter). Otherwise keep it in the app.
Every package needs tests; `melos run check:packages` fails without them.

## New package

1. Create it under `packages/` (the workspace picks up `packages/*`
   automatically):

   ```sh
   flutter create --template=package packages/analytics   # Flutter package
   # or: dart create --template=package packages/analytics  (pure Dart)
   ```

2. Edit `packages/analytics/pubspec.yaml`:

   ```yaml
   name: analytics
   description: One sentence describing the responsibility.
   version: 1.0.0
   publish_to: none

   environment:
     sdk: ^3.13.0          # must match the root pubspec
     flutter: ">=3.47.0"   # Flutter packages only

   resolution: workspace

   dependencies:
     core: any             # workspace packages resolve locally; "any" is fine

   dev_dependencies:
     flutter_test:         # or `test` for pure Dart packages
       sdk: flutter
   ```

3. Delete generated files the workspace provides centrally:
   `analysis_options.yaml` (the root one applies), `.gitignore`, `pubspec.lock`,
   and any `example/` you do not intend to maintain.

4. Structure: public API in `lib/analytics.dart` (exports only), code in
   `lib/src/`, tests in `test/`. Add a short `README.md` stating what the
   package does and what it must not depend on.

5. Depend on it from the app: add `analytics: any` to
   `apps/app/pubspec.yaml`, then run `melos bootstrap`.

6. If it must stay free of Flutter, add its name to `pureDartPackages` in
   `tool/check_packages.dart`.

7. Run `melos run validate`.

Rules the checker enforces: packages never depend on apps, no cycles,
Riverpod/go_router stay in apps, SDK constraints match the root.

## Second application

1. Create it under `apps/`:

   ```sh
   flutter create --template=app --platforms=android,ios,web --org com.acme --project-name admin apps/admin
   ```

2. In `apps/admin/pubspec.yaml`: add `resolution: workspace`, set
   `environment.sdk: ^3.13.0` and `environment.flutter: ">=3.47.0"`, remove
   `flutter_lints`, and add the workspace packages you need (`core: any`,
   `design_system: any`, ...). Delete `analysis_options.yaml` and
   `pubspec.lock`.

3. Reuse the app skeleton from `apps/app/lib`: `bootstrap.dart`,
   `app/di/providers.dart`, `app/config/`, `app/error/`. Copy, then trim.

4. Flavors: copy `android/app/build.gradle.kts` flavor blocks and
   `network_security_config.xml` files; for iOS, recreate the per-flavor
   build configurations, xcconfig files, schemes and Podfile mapping
   described in [environment-configuration.md](environment-configuration.md#identifiers-and-display-names).
   Add `config/{dev,staging,prod}.json`.

5. App-specific strings: either add them to `packages/localization` (shared)
   or give the app its own `l10n.yaml` and ARB files. `melos run codegen`
   runs `flutter gen-l10n` in every package with an `l10n.yaml`; extend
   `tool/check_codegen.dart` if the new app generates code.

6. CI: add build steps for the new app in `.github/workflows/ci.yml`;
   `tool/run_integration_tests.dart` targets `apps/app` and needs a parameter
   if the new app has integration tests.

7. Run `melos bootstrap` and `melos run validate`.
