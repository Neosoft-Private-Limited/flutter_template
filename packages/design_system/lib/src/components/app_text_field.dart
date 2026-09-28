import 'package:material_ui/material_ui.dart';

/// A labelled form field with consistent styling.
///
/// Validation is supplied by the caller through [validator], which must
/// return a localized message (or `null` when valid). Errors appear after the
/// user leaves the field or submits the form.
class AppTextField extends StatelessWidget {
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

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool enabled;
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
