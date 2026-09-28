import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Top-level navigation: bottom bar on phones, rail on larger screens.
class AppShell extends StatelessWidget {
  const new({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AdaptiveNavigationScaffold(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (index) => shell.goBranch(
        index,
        // Tapping the active tab returns to its first page.
        initialLocation: index == shell.currentIndex,
      ),
      destinations: [
        AppDestination(
          label: l10n.navHome,
          icon: Icons.widgets_outlined,
          selectedIcon: Icons.widgets,
        ),
        AppDestination(
          label: l10n.navPosts,
          icon: Icons.article_outlined,
          selectedIcon: Icons.article,
        ),
        AppDestination(
          label: l10n.navSettings,
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
        ),
      ],
      body: shell,
    );
  }
}
