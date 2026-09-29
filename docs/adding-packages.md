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
   `design_system: any`, ...). Delete `pubspec.lock`, and replace the
   generated `analysis_options.yaml` with a copy of
   `apps/app/analysis_options.yaml` (the shared rules, minus
   `public_member_api_docs`).

3. Start-up and shared screens come from `app_foundation`: call
   `initializeAppServices()` in the new app's `bootstrap.dart` and expose the
   services through your DI (see `apps/app/lib/bootstrap.dart` for Riverpod
   or `apps/app_bloc/lib/bootstrap.dart` for Bloc).

4. Flavors: the fastest path is how `apps/app_bloc` was created: copy
   `android/`, `ios/`, `web/` and `config/` from `apps/app` (without
   `build/`, `Pods/`, `.dart_tool/` and generated files), then give it its
   own identifiers:

   ```sh
   dart run tool/rename_app.dart --app-dir apps/admin \
     --android-id com.acme.admin --ios-id com.acme.admin --name "Acme Admin"
   ```

5. App-specific strings: either add them to `packages/localization` (shared)
   or give the app its own `l10n.yaml` and ARB files. `melos run codegen`
   and `codegen:check` run `flutter gen-l10n` in every member with an
   `l10n.yaml` (and `build_runner` wherever it is a dependency).

6. CI: add the app to the build loops in `.github/workflows/ci.yml` and to
   the `app` choices in `release.yml`. `melos run test:integration` picks up
   any app with an `integration_test/` folder automatically.

7. Run `melos bootstrap` and `melos run validate`.
