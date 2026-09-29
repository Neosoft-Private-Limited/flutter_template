# Security

This page summarizes the security-relevant decisions in the template and
lists what every adopting project must review. It is not a certification or
penetration test; your app's threat model, backend and data determine what
else is needed.

## What the template does

| Area | Measure | Where |
| --- | --- | --- |
| Secrets | No secrets in the repository or the app binary; build configuration contains only public values. The old generated `app_secrets.dart` pattern was removed. | `apps/app/config/`, [environment-configuration.md](environment-configuration.md#secrets) |
| Token storage | Access tokens only in `SecureStore` (Keychain `first_unlock_this_device`, Android Keystore-backed encryption). | `storage`, `SessionStore` |
| Database | Holds only non-sensitive cached content; cleared with local data. Not encrypted by default (SQLCipher/SQLite3MultipleCiphers available through the sqlite3 hook). | `packages/database` |
| Reinstall hygiene | Secrets left in the iOS Keychain by a previous install are deleted on first launch. | `StorageMigrator` |
| Data clean-up | `LocalDataCleaner.clearAll()` removes secrets, the database and preferences. | `app_foundation` (`session_store.dart`) |
| Log redaction | `Authorization`, cookies, API keys, passwords, tokens, secrets, OTPs masked in headers, query parameters and JSON bodies. | `Redactor` (`core`) |
| Network logs | Off by default; configuration validation rejects them (and debug logging) in prod. | `AppConfig` |
| Transport | HTTPS required outside `dev`; Android cleartext disabled except to local hosts in the `dev` flavor; system CAs only. | `AppConfig`, `network_security_config.xml` |
| 401 handling | The session is cleared when the API rejects the token (HTTP 401, or GraphQL `UNAUTHENTICATED`). | `AppServices.fromStores`, `GraphQLClient` |
| Retries | Only idempotent methods are retried automatically. | `RetryInterceptor` |
| Deserialization | Hand-written decoders check every field's type; malformed payloads become `ParsingFailure`, never partially built objects. | `Post.fromJson`, `ApiClient` |
| Deep links | Path parameters are validated before use; unknown paths show a not-found page. | `AppRoutes.parsePostId`, router |
| Errors | Users see localized, generic messages; developer messages and stack traces go to the `ErrorReporter`. Release builds replace the red error screen. | `FailureView`, `bootstrap.dart` |
| Android backup | `allowBackup=false`: Keystore-encrypted data cannot be restored on another device anyway, and caches stay on the device. | `AndroidManifest.xml` |
| Permissions | Only `INTERNET`. | `AndroidManifest.xml` |
| CI | Workflows default to `contents: read`; third-party actions pinned to commit SHAs (Dependabot updates them); pull-request CI needs no secrets; releases are manual and use protected GitHub environments; no workflow pushes commits. | `.github/workflows/` |
| Dependencies | Lockfile committed and enforced in CI; Dependabot for pub and Actions; `flutter pub get` reports known advisories. | `pubspec.lock`, `.github/dependabot.yml` |

## Adopter checklist

Review before your first release. Items marked *project-specific* cannot be
decided by the template.

**Configuration and secrets**

- [ ] Real API URL in `config/prod.json`; the prod build starts without the configuration error screen.
- [ ] No secret in `config/*.json`, Dart code, assets or native files (`git grep -i -E "secret|api[_-]?key|password|token"`).
- [ ] Any client-side SDK keys are restricted by package name/bundle ID/referrer on the provider side.
- [ ] Release keystore and Apple credentials stored outside the repository, with backups and limited access.

**Authentication and session** *(project-specific)*

- [ ] Sign-in flow stores tokens only through `SessionStore`/`SecureStore`.
- [ ] Token refresh implemented (for example a `QueuedInterceptor`) if your API issues refresh tokens.
- [ ] Sign-out calls `LocalDataCleaner.clearAll()` (or a narrower clean-up that meets your privacy requirements).
- [ ] `LocalDataCleaner` extended for every new store (databases, files, caches).

**Data and logging**

- [ ] Add your API's sensitive field names to `Redactor.sensitiveKeys`.
- [ ] Nothing personal or secret stored in `KeyValueStore` or `AppDatabase` (neither is encrypted); enable database encryption if you must store sensitive records.
- [ ] GraphQL: server error messages are logged, never shown to users; disable introspection and set query depth/complexity limits on the server *(project-specific)*.
- [ ] `ErrorReporter` implementation (crash reporting) scrubs personal data and URLs with credentials.
- [ ] Privacy policy, data-safety form (Google Play) and privacy manifest/nutrition labels (App Store) reflect what you collect.

**Network**

- [ ] Decide whether certificate pinning is required *(project-specific; it adds operational risk when certificates rotate)*.
- [ ] iOS ATS exceptions, if any, limited to debug/dev.
- [ ] Backend enforces authorization; the app is not a security boundary.

**Platform**

- [ ] Deep links: configure Android App Links / iOS Universal Links with domain verification if you use `https` links, and validate every parameter.
- [ ] Review permissions added by new plugins (`AndroidManifest.xml`, `Info.plist` usage descriptions).
- [ ] Decide on screenshot/recents protection for sensitive screens *(project-specific)*.
- [ ] Release builds use `--obfuscate --split-debug-info` and the symbols are stored privately.
- [ ] Web: configure a Content Security Policy and HTTPS hosting; treat web secure storage as obfuscation only.

**Supply chain and CI**

- [ ] Branch protection on `main` requiring the CI workflow.
- [ ] GitHub environment `production` protected with required reviewers.
- [ ] Dependabot PRs reviewed and merged regularly.
- [ ] New dependencies checked for maintenance, license and advisories before adding.

## Deep links

The router accepts any path from a deep link or browser URL. Rules:

- Parse and validate path/query parameters (type, range, length) in the route
  `redirect` or builder; never pass them to APIs unvalidated.
- Links must not trigger state-changing actions (payments, deletion) without
  user confirmation.
- Platform configuration is not included because it needs your domain:
  Android `intent-filter` with `android:autoVerify="true"` plus
  `assetlinks.json`; iOS Associated Domains plus `apple-app-site-association`.

## Known limitations

- `LoggingErrorReporter` logs error objects as-is; a `DioException` in an
  uncaught error can include the full request URL.
- No certificate pinning, jailbreak/root detection, or screenshot protection.
- Builds download SQLite binaries from GitHub releases through the sqlite3
  build hook (checksums verified); mirror them with the `url_pattern` hook
  option if your build environment cannot reach GitHub.
- Web builds have no Content Security Policy.

Report vulnerabilities as described in [SECURITY.md](../SECURITY.md).
