import 'package:material_ui/material_ui.dart';
import 'package:storage/storage.dart';

/// Persists user preferences in the non-secure [KeyValueStore].
final class SettingsRepository {
  /// Creates a repository that reads and writes the given store.
  const new(this._store);

  /// Key of the theme mode: `light` or `dark`; absent follows the system.
  static const themeModeKey = 'settings.theme_mode';

  /// Key of the language code; absent follows the device.
  static const localeKey = 'settings.locale';

  final KeyValueStore _store;

  /// The chosen theme mode; [ThemeMode.system] when none is saved.
  ThemeMode get themeMode => switch (_store.getString(themeModeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  /// Saves [mode]. [ThemeMode.system] removes the saved value.
  Future<void> setThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _store.remove(themeModeKey)
      : _store.setString(themeModeKey, mode.name);

  /// The chosen locale, or `null` to follow the device.
  Locale? get locale {
    final tag = _store.getString(localeKey);
    return tag == null || tag.isEmpty ? null : Locale(tag);
  }

  /// Saves the language code of [locale]; `null` removes the saved value
  /// so the app follows the device again.
  Future<void> setLocale(Locale? locale) => locale == null
      ? _store.remove(localeKey)
      : _store.setString(localeKey, locale.languageCode);
}
