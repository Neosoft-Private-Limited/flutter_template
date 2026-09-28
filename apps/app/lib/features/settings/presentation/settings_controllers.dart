import 'package:app/app/di/providers.dart';
import 'package:app/features/settings/data/settings_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(keyValueStoreProvider)),
);

/// The selected theme mode. [ThemeMode.system] follows the device.
final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(settingsRepositoryProvider).themeMode;

  Future<void> select(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
  }
}

/// The selected locale, or `null` to follow the device language (falling
/// back to English when the device language is not supported).
final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final saved = ref.watch(settingsRepositoryProvider).locale;
    // Ignore a stored locale that is no longer supported.
    return AppLocalizations.supportedLocales.contains(saved) ? saved : null;
  }

  Future<void> select(Locale? locale) async {
    if (locale == state) return;
    state = locale;
    await ref.read(settingsRepositoryProvider).setLocale(locale);
  }
}
