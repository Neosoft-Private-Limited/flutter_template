# Environment configuration

Each app has three environments, each with its own native flavor,
application identifier, display name and build configuration file. The
tables use `apps/app`; `apps/app_bloc` is identical with `.bloc` inserted
in the IDs (`com.app.flutter_template.bloc.dev`, ...) and "Bloc Template"
as the name, so both apps can be installed side by side.

| Environment | Flavor | Android application ID | iOS bundle ID | Display name | Config file |
| --- | --- | --- | --- | --- | --- |
| Development | `dev` | `com.app.flutter_template.dev` | `com.app.flutter-template.dev` | Template Dev | `apps/app/config/dev.json` |
| Staging | `staging` | `com.app.flutter_template.staging` | `com.app.flutter-template.staging` | Template Staging | `apps/app/config/staging.json` |
| Production | `prod` | `com.app.flutter_template` | `com.app.flutter-template` | Flutter Template | `apps/app/config/prod.json` |

The three variants can be installed side by side. (The previous template's
`qa` flavor is now `staging`.)

## Running and building

Always pass both the flavor and the matching configuration file (run from
`apps/app`):

```sh
flutter run   --flavor dev     --dart-define-from-file=config/dev.json
flutter run   --flavor staging --dart-define-from-file=config/staging.json
flutter build apk       --release --flavor prod --dart-define-from-file=config/prod.json
flutter build appbundle --release --flavor prod --dart-define-from-file=config/prod.json
flutter build ipa       --release --flavor prod --dart-define-from-file=config/prod.json
flutter build web       --release --dart-define-from-file=config/staging.json
```

Web has no native flavors; the environment comes from `APP_ENV` alone.

## Configuration values

Values are read with `String.fromEnvironment` in
`packages/app_foundation/lib/src/config/config_reader.dart` and validated by
`AppConfig.fromMap` (`packages/core`).

| Key | Required | Allowed values | Default |
| --- | --- | --- | --- |
| `APP_ENV` | yes (or a flavor) | `dev`, `staging`, `prod` | – |
| `API_BASE_URL` | yes | absolute URL; `https` (plain `http` only in `dev`) | – |
| `LOG_LEVEL` | no | `debug`, `info`, `warning`, `error`, `off` | `info` |
| `NETWORK_LOGS` | no | `true`, `false` | `false` |
| `GRAPHQL_URL` | no | absolute URL; same rules as `API_BASE_URL`. When set, the posts feature uses GraphQL instead of REST. | unset |

`config/dev_graphql.json` is the `dev` configuration plus a `GRAPHQL_URL`
pointing to the public GraphQLZero API, for trying the GraphQL data source.

### Precedence and validation

1. The **native flavor** (`--flavor`, exposed as `appFlavor`) selects the
   environment on Android and iOS.
2. `APP_ENV` from the configuration file must agree with the flavor. A
   mismatch (for example `--flavor prod` with `config/dev.json`) is an error.
3. Values passed with `--dart-define KEY=value` on the command line are
   combined with the file. Avoid relying on the order; put overrides in a
   local file instead (see below).
4. Defaults apply only to the optional keys.

Production adds stricter rules. The prod build refuses to start when:

- `API_BASE_URL` points to a placeholder or local host (`example.com`,
  `*.example`, `*.invalid`, `*.test`, `localhost`, `127.0.0.1`, `10.0.2.2`);
- `NETWORK_LOGS` is `true`;
- `GRAPHQL_URL` (when set) points to a placeholder or local host;
- `LOG_LEVEL` is `debug`.

When validation fails, the app shows a screen listing **every** problem
instead of starting. `config/prod.json` ships with the placeholder
`https://api.example.com` on purpose: a production build cannot go out
until someone sets the real API.

### Local overrides

Copy a file to `config/<env>.local.json` (git-ignored) and pass that instead,
for example to point `dev` at a backend on your machine:

```json
{
  "APP_ENV": "dev",
  "API_BASE_URL": "http://10.0.2.2:8080",
  "LOG_LEVEL": "debug",
  "NETWORK_LOGS": "true"
}
```

Plain HTTP to `10.0.2.2`, `localhost` and `127.0.0.1` is permitted only in the
Android `dev` flavor (`android/app/src/dev/res/xml/network_security_config.xml`).
On iOS, App Transport Security blocks plain HTTP; add an ATS exception to a
dev-only configuration if you need it.

### Adding a configuration value

1. Add the key to `ConfigKeys` and parse/validate it in
   `AppConfig.fromMap` (`packages/core/lib/src/config/app_config.dart`), with
   tests in `packages/core/test/app_config_test.dart`.
2. Add a `String.fromEnvironment` line in `config_reader.dart`
   (`packages/app_foundation`).
3. Add the key to every `config/*.json` of every app and to the table above.

## Secrets

**Anything compiled into the app is public.** `--dart-define` values, assets
and code can be extracted from an APK, IPA or web bundle. Therefore:

- Do not put API secrets, private keys or service credentials in
  `config/*.json`, Dart code or assets.
- Keep secrets on a backend you control; the app authenticates users and
  calls that backend.
- Public identifiers that SDKs expect in the client (for example a
  publishable analytics key) are acceptable, but restrict them on the
  provider side (bundle ID/package name, HTTP referrer, quotas).
- Tokens obtained at runtime go to `SecureStore` (see
  [architecture.md](architecture.md#storage)).

The previous template generated `app_secrets.dart` from a CI secret. That
pattern was removed because it compiled secrets into the binary.

## Identifiers and display names

Rename everything at once with the rename tool (commit or stash first so you
can review the diff). Pass `--app-dir apps/app_bloc` for the Bloc app:

```sh
dart run tool/rename_app.dart --android-id com.acme.shop --ios-id com.acme.shop --name "Acme Shop" --dry-run
dart run tool/rename_app.dart --android-id com.acme.shop --ios-id com.acme.shop --name "Acme Shop"
```

It updates the Android `namespace`/`applicationId`, flavor labels and Kotlin
package, the iOS per-flavor xcconfig files and test bundle ID, and the web
title and manifest. Then update `appTitle` in the ARB files and run
`melos run codegen`.

Where the values live if you prefer to edit by hand:

| What | File |
| --- | --- |
| Android IDs and names | `apps/app/android/app/build.gradle.kts` (`applicationId`, `applicationIdSuffix`, `resValue("string", "app_name", ...)`) |
| iOS bundle ID, display name, team | `apps/app/ios/Flutter/{dev,staging,prod}.xcconfig` |
| iOS build configurations | `Debug/Profile/Release-<flavor>` in `Runner.xcodeproj`, schemes `dev`, `staging`, `prod`, mapping in `ios/Podfile` |
| In-app title | `appTitle` in `packages/localization/lib/l10n/*.arb` |

## Release signing

### Android

The release build type reads signing values from environment variables
first, then from `apps/app/android/key.properties` (git-ignored):

| Environment variable | `key.properties` key |
| --- | --- |
| `ANDROID_KEYSTORE_PATH` | `storeFile` |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` |
| `ANDROID_KEY_ALIAS` | `keyAlias` |
| `ANDROID_KEY_PASSWORD` | `keyPassword` |

Without a keystore, release builds fall back to the debug key (Gradle prints
a warning) so `flutter run --release` works locally. Such builds are rejected
by Google Play.

Create a keystore (keep it and its passwords in a password manager; losing
it can prevent app updates unless you use Play App Signing):

```sh
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 4096 -validity 10000 -alias upload
```

For the **Release** workflow, add these secrets to the GitHub environments
`staging` and `production`:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -i release.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |

### iOS

Signing is not configured in the repository. To build a signed IPA locally,
set `DEVELOPMENT_TEAM` in `ios/Flutter/<flavor>.xcconfig` (or choose the team in
Xcode), then run `flutter build ipa --flavor prod --dart-define-from-file=config/prod.json`.
CI signing (certificates, provisioning profiles, App Store Connect API key)
is not included; see [the CI section of the README](../README.md#cicd).

## Optional services

Crash reporting, analytics, push notifications and payments are not included.
Integration points:

- **Crash reporting**: implement `ErrorReporter`
  (`packages/app_foundation/lib/src/error/error_reporter.dart`) and pass it
  to `bootstrap(errorReporter: ...)` in the app.
- **Analytics**: add it to `AppServices`, expose it through the app's DI
  (a provider or `RepositoryProvider`) and call it from controllers/blocs,
  not widgets.
- **Firebase**: run `flutterfire configure` per flavor and keep generated
  options files per environment.
