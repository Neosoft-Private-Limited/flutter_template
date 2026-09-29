# Adding a feature

This walks through adding a feature using a hypothetical **profile** screen
backed by `GET /me`. The posts feature is the reference implementation:
domain and data in `packages/feature_posts`, pages and view models in each
app. Steps 1–3 and 5–6 are the same for both apps; step 4 shows Riverpod
and Bloc.

## 1. Create the folders

```
apps/app/lib/features/profile/
  domain/
    profile.dart                 entity + validating fromJson
    profile_repository.dart      interface
  data/
    profile_api.dart             ApiClient calls
    profile_repository_impl.dart implements the interface
  presentation/                  (Bloc app: bloc/ and view/)
    profile_view_model.dart      repository provider + view model
    profile_page.dart            page (extends BasePage/BaseAsyncPage)
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

## 4. Presentation (Model–View–ViewModel)

Every screen is a **page** (the view) that extends the app's `BasePage` and
talks to a **view model**; the repository is the **model**. The base page
provides the scaffold, app bar, back handling and lifecycle hooks
(`onInit`, `onResume`, `onPause`, `onDispose`) from `PageLayout`, so a page
only overrides what it needs.

### Riverpod (`apps/app`)

```dart
// features/profile/presentation/profile_view_model.dart
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ProfileApi(ref.watch(apiClientProvider))),
);

class ProfileViewModel extends AsyncViewModel<Profile> {
  @override
  Future<Result<Profile>> load() =>
      ref.watch(profileRepositoryProvider).fetchProfile();

  // Intents: Future<void> save(...) async { ... }
}

final profileViewModelProvider =
    AsyncNotifierProvider<ProfileViewModel, Profile>(
      ProfileViewModel.new,
      isAutoDispose: true,
    );

// features/profile/presentation/profile_page.dart
class ProfilePage extends BaseAsyncPage<ProfileViewModel, Profile> {
  const new({super.key});

  @override
  AsyncNotifierProvider<ProfileViewModel, Profile> get viewModelProvider =>
      profileViewModelProvider;

  @override
  String title(BuildContext context) => context.l10n.profileTitle;

  @override
  Widget buildView(BuildContext context, Profile data, ProfileViewModel viewModel) =>
      Text(data.name);
}
```

`BaseAsyncPage` shows the loading spinner and the error view with a retry
button itself; `viewModel.refresh()` reloads while keeping data visible and
`viewModel.refreshError` reports a failed refresh. For screens without
loading, extend `BasePage<VM extends Notifier<S>, S>` and implement
`buildView(context, state, viewModel)` (see `SettingsPage`). Screens that
take an argument use a family provider:
`viewModelProvider => postDetailViewModelProvider(postId)`.

### Bloc (`apps/app_bloc`)

Provide the repository once in `App` (`RepositoryProvider.value`). The page
creates its own view model, which is closed when the page goes away:

```dart
// features/profile/bloc/profile_cubit.dart
class ProfileCubit extends AsyncCubit<Profile> {
  new(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Result<Profile>> load() => _repository.fetchProfile();
}

// features/profile/view/profile_page.dart
class ProfilePage extends BaseAsyncPage<ProfileCubit, Profile> {
  const new({super.key});

  @override
  ProfileCubit createViewModel(BuildContext context) =>
      ProfileCubit(context.read<ProfileRepository>());

  @override
  String title(BuildContext context) => context.l10n.profileTitle;

  @override
  Widget buildData(BuildContext context, Profile data, ProfileCubit viewModel,
          {AppFailure? refreshError}) =>
      Text(data.name);
}
```

`BaseAsyncPage` calls `fetch()` in `onInit` and renders loading and error
states. For custom states or event-driven flows, extend
`BasePage<VM extends Bloc/Cubit, S>`, start work in `onInit` and switch over
the state in `buildView` (see `PostsPage` with `PostsBloc`). Use
`onStateChanged` for one-off reactions such as snackbars or navigation.

### Rules

- Business rules live in repositories and view models, never in pages.
- Pages call intents on the view model; they do not call repositories.
- Put reusable, state-free widgets in the feature (or `design_system`) and
  pass data and callbacks into them (see `PostsListView`).

## 5. Strings

Add every user-facing string to the ARB files and run `melos run codegen`
([development.md](development.md#localization)).

## 6. Route

Add the path to `AppRoutes` and a `GoRoute` in `app/router/app_router.dart`.
For a new tab, add a `StatefulShellBranch` and an `AppDestination` in
`app/router/app_shell.dart`. Validate path parameters like
`AppRoutes.parsePostId` does.

## 7. Tests

- Repository: real `ApiClient` + `FakeHttpAdapter`, in-memory database if it
  caches (see `packages/feature_posts/test/cached_posts_repository_test.dart`).
- View model: Riverpod through widget tests or `ProviderContainer.test`;
  Bloc/Cubit with `bloc_test`
  (see `apps/app_bloc/test/features/posts/posts_bloc_test.dart`).
- Page: `TestAppHarness` with a fake repository
  (see `posts_page_test.dart` in each app); cover loading, error and success.
- Add routing assertions if the feature has deep links.

Run `melos run validate` before opening a pull request.

## When to move a feature into a package

Keep features inside the app until a second app needs them. Then move the
feature into `packages/feature_<name>` like `feature_posts` (see
[adding-packages.md](adding-packages.md)):

- `lib/src/domain`, `lib/src/data`: moved unchanged;
- `lib/src/ui`: stateless widgets that take data and callbacks
  (`PostsListView`), exported from `package:feature_<name>/widgets.dart`;
- `lib/testing.dart`: fakes for the apps' tests;
- state management and routing stay in each app (the package must not
  depend on Riverpod, Bloc or go_router).

If the feature stores data, add its tables and DAO to `packages/database`
and bump the schema version.
