# Testing

## Strategy

| Level | Where | Runs on | What it covers |
| --- | --- | --- | --- |
| Unit | `packages/*/test`, `apps/app/test` | `flutter test` (no device) | Config parsing and validation, `Result`/failures, redaction, validators, `ApiClient` + interceptors, storage contracts and migrations, repositories, serialization |
| Widget | `packages/design_system/test`, `apps/app/test` | `flutter test` (no device) | Components, accessibility guidelines, startup, routing and deep-link validation, theme and language switching, loading/empty/error/success states, forms, dialogs |
| Integration | `apps/app/integration_test` | device, emulator or simulator | Two end-to-end flows with real storage and a fake HTTP transport |

No test needs network access, credentials or a live backend.

## Commands

```sh
melos run test                 # all packages, dependency order, stops at the first failure
melos run test:coverage        # same, writes <package>/coverage/lcov.info
melos run test:integration     # needs a device; DEVICE=<id> picks one
cd packages/networking && flutter test test/api_client_test.dart   # one file
```

Generate an HTML coverage report for a package (requires `lcov`):

```sh
cd apps/app && flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
```

## Integration tests

```sh
flutter devices                                   # find a device ID
DEVICE=emulator-5554 melos run test:integration
# or, from apps/app:
flutter test integration_test --flavor dev --dart-define-from-file=config/dev.json -d <device-id>
```

The flows:

1. Browse posts, open a post, restart offline and see the cached list with
   the offline notice.
2. Choose dark theme and Spanish, restart, and find both restored.

They override the `ApiClient` with `FakeHttpAdapter` and use the real
`SharedPreferencesKeyValueStore`. CI runs them on an Android emulator through
the manual/weekly **Integration tests** workflow, not on every pull request.

## Test doubles

Use the fakes that ship with the packages instead of mocking frameworks where
possible:

| Fake | Import |
| --- | --- |
| `InMemoryKeyValueStore`, `InMemorySecureStore` | `package:storage/storage.dart` |
| `FakeHttpAdapter`, `FakeResponse`, `FakeHttpAdapter.offline()` | `package:networking/testing.dart` (tests only) |
| `FakePostsRepository`, `TestAppHarness` | `apps/app/test/helpers/test_app.dart` |

`FakeHttpAdapter` lets you exercise the real `ApiClient`, interceptors and
error mapping. `mocktail` is available in the app for cases a fake cannot
cover.

### Testing widgets that use providers

`TestAppHarness` starts the real `App` with in-memory stores, a fake
repository and a router at any location:

```dart
final harness = TestAppHarness();
harness.postsRepository.onFetchPosts = () async => const Err(NetworkFailure('x'));
await harness.pump(tester, initialLocation: '/posts');
expect(find.text('Retry'), findsOneWidget);
```

For providers without widgets, use `ProviderContainer.test(overrides: [...])`.

## Conventions

- One behaviour per test; names read as sentences
  (`'falls back to cached posts when offline'`).
- Arrange/act/assert separated by blank lines.
- Test observable behaviour (rendered text, stored values, requests sent),
  not private implementation.
- Accessibility: add `meetsGuideline(...)` checks for new reusable components
  and screens with custom controls.
- Do not delete or skip a failing test to make CI green; fix the cause or
  document why it is quarantined in the test itself.

## What is not automated

- Golden (screenshot) tests: not included; add them if your design needs
  pixel-level regression checks.
- iOS integration tests in CI: the workflow uses an Android emulator only.
  Run them locally on a simulator:
  `flutter test integration_test --flavor dev --dart-define-from-file=config/dev.json -d <simulator-id>`.
- Web integration tests: require `chromedriver` and `flutter drive`; not set up.
