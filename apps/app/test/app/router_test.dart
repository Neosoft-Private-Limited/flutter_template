import 'package:app/app/router/not_found_page.dart';
import 'package:app/app/router/routes.dart';
import 'package:app/features/home/presentation/home_page.dart';
import 'package:app/features/posts/presentation/post_detail_page.dart';
import 'package:app/features/posts/presentation/posts_page.dart';
import 'package:app/features/settings/presentation/settings_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  group('AppRoutes.parsePostId', () {
    test('accepts positive integers only', () {
      expect(AppRoutes.parsePostId('42'), 42);
      for (final raw in [null, '', '0', '-1', 'abc', '1.5', '9999999999']) {
        expect(AppRoutes.parsePostId(raw), isNull, reason: raw);
      }
    });
  });

  group('routing', () {
    late TestAppHarness harness;

    setUp(() => harness = TestAppHarness());

    testWidgets('starts on the home page', (tester) async {
      await harness.pump(tester);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('redirects / to home', (tester) async {
      await harness.pump(tester, initialLocation: '/');

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('opens a valid post deep link', (tester) async {
      await harness.pump(tester, initialLocation: '/posts/7');

      expect(find.byType(PostDetailPage), findsOneWidget);
      expect(find.text('Body 7'), findsOneWidget);
    });

    for (final location in ['/posts/abc', '/posts/0', '/unknown/path']) {
      testWidgets('shows not found for $location', (tester) async {
        await harness.pump(tester, initialLocation: location);

        expect(find.byType(NotFoundPage), findsOneWidget);
        await tester.tap(find.text('Go to home'));
        await tester.pumpAndSettle();
        expect(find.byType(HomePage), findsOneWidget);
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
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
