import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('WindowSize.fromWidth follows Material 3 breakpoints', () {
    expect(WindowSize.fromWidth(0), WindowSize.compact);
    expect(WindowSize.fromWidth(599), WindowSize.compact);
    expect(WindowSize.fromWidth(600), WindowSize.medium);
    expect(WindowSize.fromWidth(839), WindowSize.medium);
    expect(WindowSize.fromWidth(840), WindowSize.expanded);
  });

  group('AdaptiveNavigationScaffold', () {
    const destinations = [
      AppDestination(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      AppDestination(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
      ),
    ];

    Future<List<int>> pumpAtWidth(WidgetTester tester, double width) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final selections = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: AdaptiveNavigationScaffold(
            destinations: destinations,
            selectedIndex: 0,
            onDestinationSelected: selections.add,
            body: const Text('body'),
          ),
        ),
      );
      return selections;
    }

    testWidgets('uses a bottom navigation bar on compact windows', (
      tester,
    ) async {
      final selections = await pumpAtWidth(tester, 400);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      await tester.tap(find.text('Settings'));
      expect(selections, [1]);
    });

    testWidgets('uses a navigation rail on wider windows', (tester) async {
      final selections = await pumpAtWidth(tester, 1000);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.text('Settings'));
      expect(selections, [1]);
    });
  });

  testWidgets('ContentConstraint caps the width of its child', (tester) async {
    tester.view.physicalSize = const Size(1600, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ContentConstraint(child: SizedBox.expand(key: Key('child'))),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('child'))).width,
      AppSizes.maxContentWidth,
    );
  });
}
