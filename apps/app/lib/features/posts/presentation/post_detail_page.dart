import 'package:app/app/error/failure_messages.dart';
import 'package:app/features/posts/presentation/posts_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

class PostDetailPage extends ConsumerWidget {
  const new({required this.postId, super.key});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final post = ref.watch(postProvider(postId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.postTitle(postId))),
      body: switch (post) {
        AsyncData(:final value) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ContentConstraint(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    value.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(value.body, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        AsyncError(:final error) => FailureView(
          error: error,
          onRetry: () => ref.invalidate(postProvider(postId)),
        ),
        AsyncLoading() => AppLoadingView(semanticLabel: l10n.loadingLabel),
      },
    );
  }
}
