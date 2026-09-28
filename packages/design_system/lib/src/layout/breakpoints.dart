import 'package:design_system/src/tokens/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Material 3 window size classes.
enum WindowSize {
  /// Phones in portrait (< 600 dp).
  compact,

  /// Tablets in portrait, foldables, phones in landscape (600-839 dp).
  medium,

  /// Tablets in landscape, desktop, web (>= 840 dp).
  expanded;

  static const double mediumMinWidth = 600;
  static const double expandedMinWidth = 840;

  static WindowSize fromWidth(double width) {
    if (width >= expandedMinWidth) return WindowSize.expanded;
    if (width >= mediumMinWidth) return WindowSize.medium;
    return WindowSize.compact;
  }

  /// The size class of the current window. Rebuilds only when the size
  /// changes.
  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);
}

/// Centers [child] and caps its width at [maxWidth] so text stays readable on
/// large screens.
class ContentConstraint extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.maxWidth = AppSizes.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
