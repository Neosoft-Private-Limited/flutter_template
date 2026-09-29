import 'package:app/app/router/app_shell.dart';
import 'package:app/features/posts/presentation/post_detail_page.dart';
import 'package:app/features/posts/presentation/posts_page.dart';
import 'package:app/features/settings/presentation/settings_page.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The app's single router. Deep links (`/posts/42`) and browser URLs are
/// handled by the same configuration.
final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createRouter({String initialLocation = AppRoutes.home}) => GoRouter(
  initialLocation: initialLocation,
  redirect: (context, state) => state.uri.path == '/' ? AppRoutes.home : null,
  errorBuilder: (context, state) =>
      NotFoundPage(onGoHome: () => context.go(AppRoutes.home)),
  routes: [
    GoRoute(
      path: AppRoutes.notFound,
      builder: (context, state) =>
          NotFoundPage(onGoHome: () => context.go(AppRoutes.home)),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const ShowcasePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.posts,
              builder: (context, state) => const PostsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  redirect: (context, state) =>
                      AppRoutes.parsePostId(state.pathParameters['id']) == null
                      ? AppRoutes.notFound
                      : null,
                  builder: (context, state) => PostDetailPage(
                    postId: AppRoutes.parsePostId(state.pathParameters['id'])!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
