import 'package:app_bloc/features/posts/view/post_detail_page.dart';
import 'package:app_bloc/features/posts/view/posts_page.dart';
import 'package:app_bloc/features/settings/view/settings_page.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  late TestAppHarness harness;

  setUp(() => harness = TestAppHarness());

  testWidgets('starts on the showcase page', (tester) async {
    await harness.pump(tester, initialLocation: '/');

    expect(find.byType(ShowcasePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('opens a valid post deep link', (tester) async {
    await harness.pump(tester, initialLocation: '/posts/7');

    expect(find.byType(PostDetailPage), findsOneWidget);
    expect(find.text('Body 7'), findsOneWidget);
  });

  for (final location in ['/posts/abc', '/unknown']) {
    testWidgets('shows not found for $location', (tester) async {
      await harness.pump(tester, initialLocation: location);

      expect(find.byType(NotFoundPage), findsOneWidget);
      await tester.tap(find.text('Go to home'));
      await tester.pumpAndSettle();
      expect(find.byType(ShowcasePage), findsOneWidget);
    });
  }

  testWidgets('switches tabs with the navigation bar', (tester) async {
    await harness.pump(tester);

    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();
    expect(find.byType(PostsPage), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('uses a navigation rail on wide screens', (tester) async {
    await harness.pump(tester, size: const Size(1200, 800));

    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
