import 'dart:async';

import 'package:app/features/posts/presentation/post_detail_page.dart';
import 'package:core/core.dart';
import 'package:feature_posts/feature_posts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_app.dart';

void main() {
  late TestAppHarness harness;

  setUp(() => harness = TestAppHarness());

  testWidgets('shows a loading indicator, then the posts', (tester) async {
    final completer = Completer<Result<PostsFeed>>();
    harness.postsRepository.onFetchPosts = () => completer.future;

    await harness.pump(tester, initialLocation: '/posts', settle: false);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(Ok(PostsFeed([testPost(1), testPost(2)])));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Title 1'), findsOneWidget);
    expect(find.text('Title 2'), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    harness.postsRepository.onFetchPosts = () async => const Ok(PostsFeed([]));

    await harness.pump(tester, initialLocation: '/posts');

    expect(find.text('No posts yet'), findsOneWidget);
  });

  testWidgets('shows a localized error and recovers on retry', (tester) async {
    harness.postsRepository.onFetchPosts = () async =>
        const Err(NetworkFailure('offline'));

    await harness.pump(tester, initialLocation: '/posts');

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.textContaining('offline'), findsOneWidget);
    expect(find.textContaining('NetworkFailure'), findsNothing);

    harness.postsRepository.onFetchPosts = () async =>
        Ok(PostsFeed([testPost(3)]));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Title 3'), findsOneWidget);
    expect(harness.postsRepository.fetchPostsCalls, 2);
  });

  testWidgets('flags posts served from the offline cache', (tester) async {
    harness.postsRepository.onFetchPosts = () async =>
        Ok(PostsFeed([testPost(1)], isFromCache: true));

    await harness.pump(tester, initialLocation: '/posts');

    expect(find.textContaining('Showing saved posts'), findsOneWidget);
    expect(find.text('Title 1'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads the list', (tester) async {
    await harness.pump(tester, initialLocation: '/posts');
    harness.postsRepository.onFetchPosts = () async =>
        Ok(PostsFeed([testPost(9)]));

    await tester.fling(find.text('Title 1'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Title 9'), findsOneWidget);
  });

  testWidgets('opens the detail page when a post is tapped', (tester) async {
    await harness.pump(tester, initialLocation: '/posts');

    await tester.tap(find.text('Title 2'));
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailPage), findsOneWidget);
    expect(find.text('Post 2'), findsOneWidget);
    expect(find.text('Body 2'), findsOneWidget);
  });

  testWidgets('detail page shows not-found errors', (tester) async {
    harness.postsRepository.onFetchPost = (_) async =>
        const Err(NotFoundFailure('missing'));

    await harness.pump(tester, initialLocation: '/posts/5');

    expect(
      find.text('We could not find what you were looking for.'),
      findsOneWidget,
    );
  });
}
