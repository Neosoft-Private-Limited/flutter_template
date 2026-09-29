# database

Local relational storage with [drift](https://drift.simonbinder.eu) (SQLite).
This package owns the schema, DAOs and schema migrations, so every feature
shares one database and one migration history.

- `AppDatabase`: `AppDatabase.open()` on devices, `AppDatabase(NativeDatabase.memory())` in tests
- Tables: `CachedPosts` (offline copy of the example posts)
- DAOs: `PostsDao`
- `clearAll()`: used when the user clears local data

## Platforms

- **Android, iOS, desktop**: `package:sqlite3` bundles SQLite through
  Dart build hooks. The first build downloads prebuilt, checksum-verified
  binaries from the sqlite3.dart GitHub releases, so builds need network
  access to GitHub (or a mirror configured with the `url_pattern` hook
  option).
- **Web**: requires `sqlite3.wasm` and `drift_worker.js` in the app's
  `web/` folder (committed in both example apps; versions must match the
  `sqlite3` and `drift` packages, see "Upgrading").

The database is **not encrypted**. Keep secrets in `SecureStore`. For
encryption at rest, switch the hook to SQLite3MultipleCiphers or SQLCipher
(see the sqlite3 package's `doc/hook.md`) and review their licenses.

## Changing the schema

1. Edit or add a table in `lib/src/tables/` (and a DAO in `lib/src/daos/`).
2. Bump `schemaVersion` in `lib/src/app_database.dart`.
3. From this directory:

   ```sh
   dart run build_runner build          # regenerate *.g.dart
   dart run drift_dev make-migrations   # snapshot the schema, generate step helpers and tests
   ```

4. Handle the new version in `migration` (`onUpgrade: stepByStep(...)`) and
   run the generated migration tests.
5. Commit the generated files and `drift_schemas/`. `melos run codegen:check`
   fails in CI if generated files are stale.

## Upgrading drift/sqlite3

After bumping the packages, replace `web/sqlite3.wasm` and
`web/drift_worker.js` in each app with the files from the matching GitHub
releases (`sqlite3-<version>` and `drift-<version>`).
