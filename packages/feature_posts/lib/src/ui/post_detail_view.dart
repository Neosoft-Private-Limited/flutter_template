import 'package:design_system/design_system.dart';
import 'package:feature_posts/src/domain/post.dart';
import 'package:material_ui/material_ui.dart';

/// Stateless body of the post detail screen.
class PostDetailView extends StatelessWidget {
  /// Creates the detail body for [post].
  const new({required this.post, super.key});

  /// The post whose title and body are shown.
  final Post post;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ContentConstraint(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(post.title, style: textTheme.headlineSmall),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(post.body, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
