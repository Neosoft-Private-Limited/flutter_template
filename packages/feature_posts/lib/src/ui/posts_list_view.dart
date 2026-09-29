import 'package:app_foundation/app_foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_posts/src/domain/post.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Stateless posts list with pull-to-refresh, the empty state and a notice
/// for offline data or a failed refresh.
///
/// It knows nothing about the state-management library: the app passes the
/// data and callbacks from its Riverpod provider or Bloc.
class PostsListView extends StatelessWidget {
  /// Creates the list for [feed] with the given callbacks.
  const new({
    required this.feed,
    required this.onRefresh,
    required this.onOpenPost,
    super.key,
    this.refreshError,
  });

  /// The posts to show; an empty feed shows the empty state.
  final PostsFeed feed;

  /// Called on pull-to-refresh; the indicator spins until it completes.
  final Future<void> Function() onRefresh;

  /// Called with the post the user tapped.
  final ValueChanged<Post> onOpenPost;

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

    final Widget list;
    if (feed.posts.isEmpty) {
      // A scrollable child keeps pull-to-refresh working on the empty state.
      list = LayoutBuilder(
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
    } else {
      list = ContentConstraint(
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
              onTap: () => onOpenPost(post),
            );
          },
        ),
      );
    }
    return RefreshIndicator(onRefresh: onRefresh, child: list);
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
