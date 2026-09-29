# storage

Local persistence. Depends on `core`.

- `KeyValueStore` (`SharedPreferencesKeyValueStore`, `InMemoryKeyValueStore`): non-sensitive, typed preferences and small caches
- `SecureStore` (`FlutterSecureStore`, `InMemorySecureStore`): tokens and other secrets
- `StorageMigrator`, `StorageMigration`: ordered, resumable data migrations; clears leftover secrets after an iOS reinstall

Never store secrets in `KeyValueStore`. See
[docs/architecture.md](../../docs/architecture.md#storage).
