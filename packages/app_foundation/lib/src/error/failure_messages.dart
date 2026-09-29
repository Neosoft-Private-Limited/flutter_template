import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Maps failures and validation errors to localized, user-facing text.
extension FailureMessages on AppLocalizations {
  /// A user-facing, localized explanation for [error]. Never shows the
  /// developer message, which may contain technical details.
  String describeError(Object error) => switch (error) {
    NetworkFailure() => errorNetwork,
    TimeoutFailure() => errorTimeout,
    UnauthorizedFailure() => errorUnauthorized,
    NotFoundFailure() => errorNotFound,
    ServerFailure() || GraphQLFailure() => errorServer,
    ParsingFailure() => errorParsing,
    _ => errorUnknown,
  };

  /// Localized message for a validation error from `Validators`.
  String describeValidation(ValidationError error, {int minLength = 0}) =>
      switch (error) {
        ValidationError.required => validationRequired,
        ValidationError.invalidEmail => validationInvalidEmail,
        ValidationError.tooShort => validationTooShort(minLength),
      };
}

/// Standard error state for a failed load, with a retry button.
class FailureView extends StatelessWidget {
  /// Creates an error state for [error] that calls [onRetry] on retry.
  const new({required this.error, required this.onRetry, super.key});

  /// The failure to explain, usually an `AppFailure`; any other object is
  /// shown as an unknown error.
  final Object error;

  /// Called when the user taps the retry button.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppMessageView.error(
      title: l10n.errorTitle,
      message: l10n.describeError(error),
      actionLabel: l10n.retryAction,
      onAction: onRetry,
    );
  }
}
