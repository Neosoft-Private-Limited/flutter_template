import 'package:material_ui/material_ui.dart';

enum AppButtonVariant {
  /// High emphasis: the main action of a screen ([FilledButton]).
  primary,

  /// Medium emphasis ([OutlinedButton]).
  secondary,

  /// Low emphasis ([TextButton]).
  text,
}

/// The button used across the app.
///
/// While [isLoading] is `true` the button is disabled, shows a progress
/// indicator and announces [loadingLabel] to screen readers, which prevents
/// duplicate submissions.
class AppButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
    this.expand = false,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Screen reader label while [isLoading]. Pass a localized string.
  final String? loadingLabel;

  /// Stretch to the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final callback = isLoading ? null : onPressed;
    final content = isLoading
        ? Semantics(
            label: loadingLabel,
            child: const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : Text(label);
    final iconWidget = icon == null || isLoading ? null : Icon(icon);

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton.icon(
        onPressed: callback,
        icon: iconWidget,
        label: content,
      ),
      AppButtonVariant.secondary => OutlinedButton.icon(
        onPressed: callback,
        icon: iconWidget,
        label: content,
      ),
      AppButtonVariant.text => TextButton.icon(
        onPressed: callback,
        icon: iconWidget,
        label: content,
      ),
    };

    return Semantics(
      button: true,
      label: isLoading ? loadingLabel : null,
      child: expand ? SizedBox(width: double.infinity, child: button) : button,
    );
  }
}
