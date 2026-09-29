/// Why a value was rejected. The UI maps these to localized messages, so
/// validation logic stays free of user-facing strings.
enum ValidationError {
  /// The value is missing or blank.
  required,

  /// The value is not a plausible email address.
  invalidEmail,

  /// The value has fewer characters than the minimum.
  tooShort,
}

/// Pure input validators. Each returns `null` when the value is valid.
abstract final class Validators {
  // Pragmatic check: one "@", non-empty local part, dotted domain without
  // spaces. Full RFC 5322 validation belongs on the server.
  static final RegExp _email = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  /// Rejects `null`, empty and whitespace-only values with
  /// [ValidationError.required].
  static ValidationError? required(String? value) =>
      (value == null || value.trim().isEmpty) ? ValidationError.required : null;

  /// Checks [value], trimmed, for a plausible email address.
  ///
  /// Returns [ValidationError.required] when blank and
  /// [ValidationError.invalidEmail] when malformed. This is a pragmatic check;
  /// the server remains the authority.
  static ValidationError? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return ValidationError.required;
    return _email.hasMatch(trimmed) ? null : ValidationError.invalidEmail;
  }

  /// Requires [value] to have at least [length] characters (not trimmed).
  ///
  /// Returns [ValidationError.required] when `null` or empty and
  /// [ValidationError.tooShort] when shorter than [length].
  static ValidationError? minLength(String? value, int length) {
    if (value == null || value.isEmpty) return ValidationError.required;
    return value.length < length ? ValidationError.tooShort : null;
  }
}
