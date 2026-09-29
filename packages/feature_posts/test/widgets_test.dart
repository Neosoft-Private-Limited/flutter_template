import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:feature_posts/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Post post(int id) => Post(id: id, userId: 1, title: 'T$id', body: 'B$id');

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );

  testWidgets('PostsListView shows posts and reports taps', (tester) async {
    final opened = <int>[];
    await pump(
      tester,
      PostsListView(
        feed: PostsFeed([post(1), post(2)]),
        onRefresh: () async {},
        onOpenPost: (p) => opened.add(p.id),
      ),
    );

    await tester.tap(find.text('T2'));

    expect(opened, [2]);
  });

  testWidgets('PostsListView flags cached data and failed refreshes', (
    tester,
  ) async {
    await pump(
      tester,
      PostsListView(
        feed: PostsFeed([post(1)], isFromCache: true),
        onRefresh: () async {},
        onOpenPost: (_) {},
      ),
    );
    expect(find.textContaining('Showing saved posts'), findsOneWidget);

    await pump(
      tester,
      PostsListView(
        feed: PostsFeed([post(1)]),
        refreshError: const TimeoutFailure('x'),
        onRefresh: () async {},
        onOpenPost: (_) {},
      ),
    );
    expect(find.textContaining('took too long'), findsOneWidget);
  });

  testWidgets('PostsListView shows the empty state', (tester) async {
    await pump(
      tester,
      PostsListView(
        feed: const PostsFeed([]),
        onRefresh: () async {},
        onOpenPost: (_) {},
      ),
    );

    expect(find.text('No posts yet'), findsOneWidget);
  });

  testWidgets('PostDetailView shows title as a heading and the body', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, PostDetailView(post: post(3)));

    expect(find.text('B3'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('T3')),
      matchesSemantics(label: 'T3', isHeader: true),
    );
    handle.dispose();
  });
}
