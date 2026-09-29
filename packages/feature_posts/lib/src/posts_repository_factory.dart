import 'package:database/database.dart';
import 'package:feature_posts/src/data/cached_posts_repository.dart';
import 'package:feature_posts/src/data/graphql_posts_data_source.dart';
import 'package:feature_posts/src/data/posts_local_data_source.dart';
import 'package:feature_posts/src/data/rest_posts_data_source.dart';
import 'package:feature_posts/src/domain/posts_repository.dart';
import 'package:networking/networking.dart';

/// Builds the posts repository. Uses GraphQL when [graphQLClient] is given
/// (the app passes one when `GRAPHQL_URL` is configured), REST otherwise.
PostsRepository createPostsRepository({
  required ApiClient apiClient,
  required AppDatabase database,
  GraphQLClient? graphQLClient,
}) => CachedPostsRepository(
  remote: graphQLClient == null
      ? RestPostsDataSource(apiClient)
      : GraphQLPostsDataSource(graphQLClient),
  local: PostsLocalDataSource(database.postsDao),
);
