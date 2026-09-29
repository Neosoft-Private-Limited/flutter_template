import 'package:app_bloc/app/base/base_page.dart';
import 'package:app_bloc/features/posts/bloc/post_detail_cubit.dart';
import 'package:core/core.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:feature_posts/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

class PostDetailPage extends BaseAsyncPage<PostDetailCubit, Post> {
  const new({required this.postId, super.key});

  final int postId;

  @override
  PostDetailCubit createViewModel(BuildContext context) =>
      PostDetailCubit(context.read<PostsRepository>(), postId);

  @override
  String title(BuildContext context) => context.l10n.postTitle(postId);

  @override
  Widget buildData(
    BuildContext context,
    Post data,
    PostDetailCubit viewModel, {
    AppFailure? refreshError,
  }) => PostDetailView(post: data);
}
