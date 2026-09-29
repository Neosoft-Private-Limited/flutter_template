import 'package:app_bloc/app/base/base_page.dart';
import 'package:app_bloc/features/posts/bloc/posts_bloc.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:feature_posts/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Example feature: a list loaded from the API with loading, empty, error,
/// offline and success states, driven by an event-based [PostsBloc].
class PostsPage extends BasePage<PostsBloc, PostsState> {
  const new({super.key});

  @override
  PostsBloc createViewModel(BuildContext context) =>
      PostsBloc(context.read<PostsRepository>());

  @override
  void onInit(PostsBloc viewModel) => viewModel.add(const PostsRequested());

  @override
  String title(BuildContext context) => context.l10n.postsTitle;

  @override
  Widget buildView(
    BuildContext context,
    PostsState state,
    PostsBloc viewModel,
  ) => switch (state) {
    PostsLoading() => AppLoadingView(semanticLabel: context.l10n.loadingLabel),
    PostsFailure(:final error) => FailureView(
      error: error,
      onRetry: () => viewModel.add(const PostsRequested()),
    ),
    PostsLoaded(:final feed, :final refreshError) => PostsListView(
      feed: feed,
      refreshError: refreshError,
      onRefresh: () => _refresh(viewModel),
      onOpenPost: (post) => context.go(AppRoutes.post(post.id)),
    ),
  };

  /// Completes when the refresh finishes, so the indicator stays visible.
  static Future<void> _refresh(PostsBloc bloc) async {
    bloc.add(const PostsRefreshed());
    await bloc.stream.firstWhere((state) => !state.isBusy);
  }
}
