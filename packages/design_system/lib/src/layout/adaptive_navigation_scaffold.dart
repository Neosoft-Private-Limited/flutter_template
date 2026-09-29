import 'package:design_system/src/layout/breakpoints.dart';
import 'package:material_ui/material_ui.dart';

/// A top-level destination of [AdaptiveNavigationScaffold].
final class AppDestination {
  /// Creates a destination with a [label] and its unselected and selected
  /// icons.
  const new({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// Text shown under or beside the icon; also its accessibility label.
  final String label;

  /// Icon shown while the destination is not selected, typically the
  /// outlined variant.
  final IconData icon;

  /// Icon shown while the destination is selected, typically the filled
  /// variant.
  final IconData selectedIcon;
}

/// Shows a bottom [NavigationBar] on compact windows and a [NavigationRail]
/// on medium and expanded windows.
class AdaptiveNavigationScaffold extends StatelessWidget {
  /// Creates a scaffold that switches navigation style with the window size.
  const new({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    super.key,
  });

  /// Top-level destinations, in display order. Material recommends three to
  /// five.
  final List<AppDestination> destinations;

  /// Index into [destinations] of the currently selected destination.
  final int selectedIndex;

  /// Called with the index of the destination the user taps. Update
  /// [selectedIndex] and the [body] in response.
  final ValueChanged<int> onDestinationSelected;

  /// Content of the selected destination, shown beside the rail or above
  /// the bottom bar.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final windowSize = WindowSize.of(context);

    if (windowSize == WindowSize.compact) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            right: false,
            child: NavigationRail(
              extended: windowSize == WindowSize.expanded,
              labelType: windowSize == WindowSize.expanded
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
