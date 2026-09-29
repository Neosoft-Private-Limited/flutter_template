import 'package:app_bloc/app/base/async_cubit.dart';
import 'package:core/core.dart';
import 'package:feature_posts/feature_posts.dart';

/// View model of one post. [AsyncCubit] provides loading, error and refresh
/// handling; this class only says how to load.
class PostDetailCubit extends AsyncCubit<Post> {
  new(this._repository, this.postId);

  final PostsRepository _repository;
  final int postId;

  @override
  Future<Result<Post>> load() => _repository.fetchPost(postId);
}
