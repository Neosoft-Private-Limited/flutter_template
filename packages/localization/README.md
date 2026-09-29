# localization

Localized strings generated with `flutter gen-l10n`.

- Source: `lib/l10n/app_<locale>.arb` (English is the template and fallback)
- Generated (committed): `lib/src/generated/`
- API: `AppLocalizations`, `context.l10n`

Regenerate with `melos run codegen`. Register `AppLocalizations.delegate`
together with `GlobalMaterialLocalizations.delegates` from `material_ui`. See
[docs/development.md](../../docs/development.md#localization).
