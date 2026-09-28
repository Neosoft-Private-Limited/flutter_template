import 'package:material_ui/material_ui.dart';
import 'package:storage/storage.dart';

/// Persists user preferences in the non-secure [KeyValueStore].
final class SettingsRepository {
  const new(this._store);

  static const themeModeKey = 'settings.theme_mode';
  static const localeKey = 'settings.locale';

  final KeyValueStore _store;

  ThemeMode get themeMode => switch (_store.getString(themeModeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> setThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _store.remove(themeModeKey)
      : _store.setString(themeModeKey, mode.name);

  /// The chosen locale, or `null` to follow the device.
  Locale? get locale {
    final tag = _store.getString(localeKey);
    return tag == null || tag.isEmpty ? null : Locale(tag);
  }

  Future<void> setLocale(Locale? locale) => locale == null
      ? _store.remove(localeKey)
      : _store.setString(localeKey, locale.languageCode);
}
