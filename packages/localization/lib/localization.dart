/// Localized strings generated from `lib/l10n/*.arb`.
///
/// Apps register [AppLocalizations.delegate] together with the Material
/// delegates from `material_ui` (not the generated `localizationsDelegates`
/// list, which targets the legacy `package:flutter/material.dart`):
///
/// ```dart
/// localizationsDelegates: [
///   AppLocalizations.delegate,
///   ...GlobalMaterialLocalizations.delegates,
/// ],
/// supportedLocales: AppLocalizations.supportedLocales,
/// ```
library;

import 'package:flutter/widgets.dart';
import 'package:localization/src/generated/app_localizations.dart';

export 'src/generated/app_localizations.dart' show AppLocalizations;

extension AppLocalizationsContext on BuildContext {
  /// Shorthand for `AppLocalizations.of(context)`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
