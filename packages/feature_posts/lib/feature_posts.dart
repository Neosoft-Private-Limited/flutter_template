/// Posts feature: domain, data sources and repository. Stateless widgets are
/// in `package:feature_posts/widgets.dart`; apps add state management.
library;

export 'src/data/cached_posts_repository.dart';
export 'src/data/graphql_posts_data_source.dart';
export 'src/data/posts_local_data_source.dart';
export 'src/data/posts_remote_data_source.dart';
export 'src/data/rest_posts_data_source.dart';
export 'src/domain/post.dart';
export 'src/domain/posts_repository.dart';
export 'src/posts_repository_factory.dart';
