import 'package:material_ui/material_ui.dart';

/// A labelled form field with consistent styling.
///
/// Validation is supplied by the caller through [validator], which must
/// return a localized message (or `null` when valid). Errors appear after the
/// user leaves the field or submits the form.
class AppTextField extends StatelessWidget {
  /// Creates a text field labelled with [label].
  const new({
    required this.label,
    super.key,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.onFieldSubmitted,
  });

  /// Floating label text of the field; also used as its accessibility
  /// label.
  final String label;

  /// Controls the text being edited. When `null`, the field manages its own
  /// text internally.
  final TextEditingController? controller;

  /// Placeholder shown while the field is empty and focused, e.g. an
  /// example value. `null` shows no hint.
  final String? hint;

  /// Returns a localized error message for invalid input, or `null` when
  /// valid. `null` disables validation.
  final FormFieldValidator<String>? validator;

  /// Type of on-screen keyboard to show, e.g. [TextInputType.emailAddress].
  /// `null` uses the platform default text keyboard.
  final TextInputType? keyboardType;

  /// Action button shown on the keyboard, e.g. [TextInputAction.next] to
  /// move to the next field. `null` lets the platform choose.
  final TextInputAction? textInputAction;

  /// Hints for platform autofill and password managers, such as
  /// [AutofillHints.email]. `null` disables autofill for this field.
  final Iterable<String>? autofillHints;

  /// Whether to hide the entered text, for passwords and other secrets.
  /// Defaults to `false`.
  final bool obscureText;

  /// Whether the field accepts input; a disabled field is shown greyed out.
  /// Defaults to `true`.
  final bool enabled;

  /// Called with the current text when the user presses the keyboard's
  /// action button, e.g. to submit the form from the last field.
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    obscureText: obscureText,
    enabled: enabled,
    onFieldSubmitted: onFieldSubmitted,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    decoration: InputDecoration(labelText: label, hintText: hint),
  );
}
