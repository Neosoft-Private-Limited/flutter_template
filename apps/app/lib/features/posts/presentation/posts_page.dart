import 'package:app/app/base/base_page.dart';
import 'package:app/features/posts/presentation/posts_view_models.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:feature_posts/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Example feature: a list loaded from the API with loading, empty, error,
/// offline and success states. Loading and error states come from
/// [BaseAsyncPage]; the list widget comes from `feature_posts`.
class PostsPage extends BaseAsyncPage<PostsViewModel, PostsFeed> {
  const new({super.key});

  @override
  AsyncNotifierProvider<PostsViewModel, PostsFeed> get viewModelProvider =>
      postsViewModelProvider;

  @override
  String title(BuildContext context) => context.l10n.postsTitle;

  @override
  Widget buildView(
    BuildContext context,
    PostsFeed data,
    PostsViewModel viewModel,
  ) => PostsListView(
    feed: data,
    refreshError: viewModel.refreshError,
    onRefresh: viewModel.refresh,
    onOpenPost: (post) => context.go(AppRoutes.post(post.id)),
  );
}
