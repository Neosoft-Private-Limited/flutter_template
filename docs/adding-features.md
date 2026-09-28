# Adding a feature

This walks through adding a feature to `apps/app`, using a hypothetical
**profile** screen backed by `GET /me`. The `posts` feature is the reference
implementation; copy from it.

## 1. Create the folders

```
apps/app/lib/features/profile/
  domain/
    profile.dart                 entity + validating fromJson
    profile_repository.dart      interface
  data/
    profile_api.dart             ApiClient calls
    profile_repository_impl.dart implements the interface
  presentation/
    profile_providers.dart       repository provider + controller
    profile_page.dart            UI
apps/app/test/features/profile/
```

Skip what you do not need: a screen without I/O needs only `presentation/`.

## 2. Domain

```dart
@immutable
final class Profile {
  const new({required this.id, required this.name});

  factory fromJson(Object? json) => switch (json) {
    {'id': final int id, 'name': final String name} => Profile(id: id, name: name),
    _ => throw FormatException('Invalid profile payload', json),
  };

  final int id;
  final String name;
}

abstract interface class ProfileRepository {
  Future<Result<Profile>> fetchProfile();
}
```

## 3. Data

```dart
final class ProfileApi {
  const new(this._client);
  final ApiClient _client;

  Future<Result<Profile>> getProfile() =>
      _client.get('me', decode: Profile.fromJson);
}
```

Paths are relative (`'me'`, not `'/me'`). The `ApiClient` already attaches the
token, retries safe requests, logs (when enabled) and maps errors.

## 4. Presentation

```dart
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ProfileApi(ref.watch(apiClientProvider))),
);

final profileProvider = FutureProvider<Profile>(
  (ref) async => (await ref.watch(profileRepositoryProvider).fetchProfile()).getOrThrow(),
  isAutoDispose: true,
);
```

In the page, render the three states with the shared components:

```dart
switch (ref.watch(profileProvider)) {
  AsyncData(:final value) => Text(value.name),
  AsyncError(:final error) => FailureView(error: error, onRetry: () => ref.invalidate(profileProvider)),
  AsyncLoading() => AppLoadingView(semanticLabel: context.l10n.loadingLabel),
}
```

Use an `AsyncNotifier` (see `PostsController`) when the screen has actions
such as refresh, pagination or submit.

## 5. Strings

Add every user-facing string to the ARB files and run `melos run codegen`
([development.md](development.md#localization)).

## 6. Route

Add the path to `AppRoutes` and a `GoRoute` in `app/router/app_router.dart`.
For a new tab, add a `StatefulShellBranch` and an `AppDestination` in
`app/router/app_shell.dart`. Validate path parameters like
`AppRoutes.parsePostId` does.

## 7. Tests

- Repository: real `ApiClient` + `FakeHttpAdapter`
  (see `cached_posts_repository_test.dart`).
- Page: `TestAppHarness` with an overridden repository provider
  (see `posts_page_test.dart`); cover loading, error and success.
- Add routing assertions if the feature has deep links.

Run `melos run validate` before opening a pull request.

## When to move a feature into a package

Keep features inside the app until a second app needs them. Then move the
feature into `packages/feature_<name>` (see
[adding-packages.md](adding-packages.md)). Its providers can stay in the
package if both apps use Riverpod; otherwise expose plain classes and let
each app create providers.
