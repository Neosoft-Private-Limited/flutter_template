import 'package:material_ui/material_ui.dart';

/// Spacing scale (logical pixels). Use these instead of magic numbers.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radius scale.
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Fixed sizes shared by components.
abstract final class AppSizes {
  /// Minimum interactive size recommended by Material and the platform
  /// accessibility guidelines (48x48 dp).
  static const double minTouchTarget = 48;

  /// Maximum width of readable content on large screens.
  static const double maxContentWidth = 840;

  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 48;
}

/// Motion durations.
abstract final class AppDurations {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
}

/// Brand colors. The whole palette is derived from [seed] with Material 3's
/// tonal color system, which keeps light and dark themes accessible.
abstract final class AppColors {
  /// Replace with your brand color.
  static const Color seed = Color(0xFF3F51B5);
}
