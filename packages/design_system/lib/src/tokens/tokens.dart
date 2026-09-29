import 'package:material_ui/material_ui.dart';

/// Spacing scale (logical pixels). Use these instead of magic numbers.
abstract final class AppSpacing {
  /// 2 dp. Hairline gap, e.g. between a label and its badge or underline.
  static const double xxs = 2;

  /// 4 dp. Tight gap between an icon and its text, or stacked captions.
  static const double xs = 4;

  /// 8 dp. Gap between related elements inside a component, such as a
  /// title and its message.
  static const double sm = 8;

  /// 12 dp. Vertical padding inside inputs and compact containers.
  static const double md = 12;

  /// 16 dp. Default screen edge padding and gap between list items or form
  /// fields.
  static const double lg = 16;

  /// 24 dp. Separation between sections or groups, and padding around
  /// standalone content such as empty and error states.
  static const double xl = 24;

  /// 32 dp. Large separation between major blocks of a screen.
  static const double xxl = 32;

  /// 48 dp. Generous whitespace, e.g. above a hero or below a page header
  /// on large screens.
  static const double xxxl = 48;
}

/// Corner radius scale.
abstract final class AppRadius {
  /// 4 dp. Small elements such as chips, badges and tooltips.
  static const double sm = 4;

  /// 8 dp. Buttons and text fields.
  static const double md = 8;

  /// 12 dp. Cards and other contained surfaces.
  static const double lg = 12;

  /// 16 dp. Dialogs, bottom sheets and other large surfaces.
  static const double xl = 16;

  /// [sm] on all four corners.
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));

  /// [md] on all four corners; used by buttons and input borders.
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));

  /// [lg] on all four corners; used by cards.
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));

  /// [xl] on all four corners; used by dialogs.
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// Fixed sizes shared by components.
abstract final class AppSizes {
  /// Minimum interactive size recommended by Material and the platform
  /// accessibility guidelines (48x48 dp).
  static const double minTouchTarget = 48;

  /// Maximum width of readable content on large screens.
  static const double maxContentWidth = 840;

  /// Icons inside dense controls, such as text field prefixes or chips.
  static const double iconSm = 20;

  /// Default Material icon size for buttons, app bars and list tiles.
  static const double iconMd = 24;

  /// Illustrative icons, such as the one heading an empty or error state.
  static const double iconLg = 48;
}

/// Motion durations.
abstract final class AppDurations {
  /// 150 ms. Small, quick changes such as fades, color and state changes.
  static const Duration short = Duration(milliseconds: 150);

  /// 250 ms. Larger transitions such as expanding panels or moving elements.
  static const Duration medium = Duration(milliseconds: 250);
}

/// Brand colors. The whole palette is derived from [seed] with Material 3's
/// tonal color system, which keeps light and dark themes accessible.
abstract final class AppColors {
  /// Replace with your brand color.
  static const Color seed = Color(0xFF3F51B5);
}
