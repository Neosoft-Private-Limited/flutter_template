# app_foundation

The app shell shared by every app, independent of the state-management
library. Apps add only their state management, DI wiring and routing.

- Start-up: `initializeAppServices()` (config → logging → error handlers →
  storage and migrations) returning `AppServices`, the composition root
- Configuration: `readAppConfig()`
- Errors: `ErrorReporter`, `installErrorHandlers`, `FailureView`,
  `describeError`, `ConfigErrorApp`
- Session and data: `SessionStore`, `LocalDataCleaner`
- Settings: `SettingsRepository`
- Shared screens: `ShowcasePage`, `SettingsView`, `NotFoundPage`
- Routes: `AppRoutes` (paths and deep-link parameter validation)

Must not depend on Riverpod, Bloc or go_router (`melos run check:packages`
enforces this).
