import 'package:app/app/error/failure_messages.dart';
import 'package:app/app/router/routes.dart';
import 'package:app/features/posts/domain/post.dart';
import 'package:app/features/posts/presentation/posts_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Example feature: a list loaded from the API with loading, empty, error,
/// offline and success states.
class PostsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final posts = ref.watch(postsControllerProvider);
    final controller = ref.read(postsControllerProvider.notifier);

    final Widget body;
    if (posts.value case final feed?) {
      body = RefreshIndicator(
        onRefresh: controller.refresh,
        child: _PostsList(feed: feed, refreshError: posts.error),
      );
    } else if (posts.hasError) {
      body = FailureView(
        error: posts.error!,
        onRetry: () => ref.invalidate(postsControllerProvider),
      );
    } else {
      body = AppLoadingView(semanticLabel: l10n.loadingLabel);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.postsTitle)),
      body: body,
    );
  }
}

class _PostsList extends StatelessWidget {
  const new({required this.feed, required this.refreshError});

  final PostsFeed feed;

  /// Set when a refresh failed while older data is still shown.
  final Object? refreshError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notice = switch ((feed.isFromCache, refreshError)) {
      (true, _) => l10n.postsCachedNotice,
      (false, final Object error) => l10n.describeError(error),
      _ => null,
    };

    if (feed.posts.isEmpty) {
      // A scrollable child keeps pull-to-refresh working on the empty state.
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: AppMessageView.empty(
              title: l10n.postsEmptyTitle,
              message: l10n.postsEmptyMessage,
            ),
          ),
        ),
      );
    }

    return ContentConstraint(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        itemCount: feed.posts.length + (notice == null ? 0 : 1),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (notice != null && index == 0) return _Notice(notice);
          final post = feed.posts[index - (notice == null ? 0 : 1)];
          return ListTile(
            title: Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              post.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => context.go(AppRoutes.post(post.id)),
          );
        },
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const new(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        color: colors.secondaryContainer,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: colors.onSecondaryContainer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
