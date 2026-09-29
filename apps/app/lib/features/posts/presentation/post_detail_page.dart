import 'package:app/app/base/base_page.dart';
import 'package:app/features/posts/presentation/posts_view_models.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:feature_posts/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

class PostDetailPage extends BaseAsyncPage<PostDetailViewModel, Post> {
  const new({required this.postId, super.key});

  final int postId;

  @override
  AsyncNotifierProvider<PostDetailViewModel, Post> get viewModelProvider =>
      postDetailViewModelProvider(postId);

  @override
  String title(BuildContext context) => context.l10n.postTitle(postId);

  @override
  Widget buildView(
    BuildContext context,
    Post data,
    PostDetailViewModel viewModel,
  ) => PostDetailView(post: data);
}
