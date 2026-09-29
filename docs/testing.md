# Testing

## Strategy

| Level | Where | Runs on | What it covers |
| --- | --- | --- | --- |
| Unit | `packages/*/test`, `apps/*/test` | `flutter test` (no device) | Config parsing and validation, `Result`/failures, redaction, validators, `ApiClient`/`GraphQLClient` + interceptors, storage contracts and migrations, drift DAOs (in-memory SQLite), repositories (REST and GraphQL), serialization, blocs/cubits (`bloc_test`) |
| Widget | `packages/{design_system,app_foundation,feature_posts}/test`, `apps/*/test` | `flutter test` (no device) | Components, accessibility guidelines, startup, routing and deep-link validation, theme and language switching, loading/empty/error/success states, forms, dialogs, clearing local data |
| Integration | `apps/*/integration_test` | device, emulator or simulator | End-to-end flows per app with real storage (preferences and on-device SQLite) and a fake HTTP transport |

Totals at the time of writing: 197 unit/widget tests across 10 workspace
members, and 4 integration tests (2 per app). Database tests run against
real SQLite in memory (`NativeDatabase.memory()`), which `flutter test`
provides through the sqlite3 build hook.

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
DEVICE=emulator-5554 melos run test:integration            # every app
DEVICE=emulator-5554 APP=apps/app_bloc melos run test:integration   # one app
# or, from an app directory:
flutter test integration_test --flavor dev --dart-define-from-file=config/dev.json -d <device-id>
```

The flows (both apps):

1. Browse posts, open a post, restart offline and see the list served from
   the SQLite cache with the offline notice; open a cached post offline.
2. Choose dark theme (and Spanish in the Riverpod app), restart, and find
   the choices restored.

They build `AppServices.fromStores` with a `FakeHttpAdapter`, the real
`SharedPreferencesKeyValueStore` and an on-device `AppDatabase`. CI runs
them on an Android emulator through the manual/weekly **Integration tests**
workflow, not on every pull request.

## Test doubles

Use the fakes that ship with the packages instead of mocking frameworks where
possible:

| Fake | Import |
| --- | --- |
| `InMemoryKeyValueStore`, `InMemorySecureStore` | `package:storage/storage.dart` |
| `FakeHttpAdapter`, `FakeResponse`, `FakeHttpAdapter.offline()` | `package:networking/testing.dart` (tests only) |
| `FakePostsRepository`, `testPost` | `package:feature_posts/testing.dart` (tests only) |
| `AppDatabase(NativeDatabase.memory())` | `package:database/database.dart` + `package:drift/native.dart` |
| `TestAppHarness` | `apps/<app>/test/helpers/test_app.dart` |

`FakeHttpAdapter` lets you exercise the real `ApiClient`, interceptors and
error mapping. Add a mocking library (for example `mocktail`) only for cases
a fake cannot cover.

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

### Testing blocs

Use `bloc_test` (see `apps/app_bloc/test/features/posts/posts_bloc_test.dart`):

```dart
blocTest<PostsBloc, PostsState>(
  'failed refresh keeps the old list and exposes the error',
  build: () => PostsBloc(repository..onFetchPosts = () async => const Err(offline)),
  seed: () => PostsLoaded(feed),
  act: (bloc) => bloc.add(const PostsRefreshed()),
  expect: () => [
    PostsLoaded(feed, isRefreshing: true),
    PostsLoaded(feed, refreshError: offline),
  ],
);
```

Bloc always emits the first state even when it equals the initial state, so
a first load expects `[PostsLoading(), PostsLoaded(...)]`. States implement
`==` so expectations compare values.

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
