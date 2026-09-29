import 'package:app_foundation/app_foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// The selected theme mode. [ThemeMode.system] follows the device.
class ThemeCubit extends Cubit<ThemeMode> {
  new(this._settings) : super(_settings.themeMode);

  final SettingsRepository _settings;

  Future<void> select(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _settings.setThemeMode(mode);
  }

  /// Re-reads the stored value (after local data was cleared).
  void reload() => emit(_settings.themeMode);
}

/// The selected locale, or `null` to follow the device language (falling
/// back to English when the device language is not supported).
class LocaleCubit extends Cubit<Locale?> {
  new(this._settings) : super(_supported(_settings.locale));

  final SettingsRepository _settings;

  Future<void> select(Locale? locale) async {
    if (locale == state) return;
    emit(locale);
    await _settings.setLocale(locale);
  }

  void reload() => emit(_supported(_settings.locale));

  // Ignore a stored locale that is no longer supported.
  static Locale? _supported(Locale? locale) =>
      AppLocalizations.supportedLocales.contains(locale) ? locale : null;
}
