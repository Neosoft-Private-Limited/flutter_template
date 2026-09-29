# feature_posts

The example feature, shared by `apps/app` (Riverpod) and `apps/app_bloc`
(Bloc). It contains everything except state management and routing:

- Domain: `Post`, `PostsFeed`, `PostsRepository`
- Data: `RestPostsDataSource` and `GraphQLPostsDataSource` (same interface,
  chosen by `createPostsRepository` depending on `GRAPHQL_URL`),
  `PostsLocalDataSource` (drift), `CachedPostsRepository` (network first,
  offline fallback)
- Widgets (`package:feature_posts/widgets.dart`): `PostsListView`,
  `PostDetailView`, stateless; apps pass data and callbacks
- Test doubles (`package:feature_posts/testing.dart`): `FakePostsRepository`,
  `testPost`

Use it as the pattern for features shared by several apps; single-app
features can live inside the app (see docs/adding-features.md).
