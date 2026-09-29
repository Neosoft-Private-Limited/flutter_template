import 'dart:async';

import 'package:app_bloc/features/posts/view/post_detail_page.dart';
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

    expect(find.text('Title 1'), findsOneWidget);
    expect(find.text('Title 2'), findsOneWidget);
  });

  testWidgets('shows a localized error and recovers on retry', (tester) async {
    harness.postsRepository.onFetchPosts = () async =>
        const Err(NetworkFailure('offline'));

    await harness.pump(tester, initialLocation: '/posts');
    expect(find.textContaining('offline'), findsOneWidget);

    harness.postsRepository.onFetchPosts = () async =>
        Ok(PostsFeed([testPost(3)]));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Title 3'), findsOneWidget);
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
    expect(find.text('Body 2'), findsOneWidget);
  });

  testWidgets('detail page shows not-found errors and retries', (tester) async {
    harness.postsRepository.onFetchPost = (_) async =>
        const Err(NotFoundFailure('missing'));

    await harness.pump(tester, initialLocation: '/posts/5');
    expect(
      find.text('We could not find what you were looking for.'),
      findsOneWidget,
    );

    harness.postsRepository.onFetchPost = (id) async => Ok(testPost(id));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Body 5'), findsOneWidget);
  });
}
