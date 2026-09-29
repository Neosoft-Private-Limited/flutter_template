import 'package:app/app/di/providers.dart';
import 'package:app/features/posts/presentation/posts_view_models.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

// App-wide settings state (read by MaterialApp) ---------------------------

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

// Settings screen view model -------------------------------------------------

@immutable
final class SettingsState {
  const new({
    required this.config,
    required this.themeMode,
    required this.locale,
  });

  final AppConfig config;
  final ThemeMode themeMode;
  final Locale? locale;
}

/// View model of the settings screen: derives its state from the app-wide
/// providers and exposes the screen's intents.
class SettingsViewModel extends Notifier<SettingsState> {
  @override
  SettingsState build() => SettingsState(
    config: ref.watch(appConfigProvider),
    themeMode: ref.watch(themeModeProvider),
    locale: ref.watch(localeProvider),
  );

  Future<void> selectThemeMode(ThemeMode mode) =>
      ref.read(themeModeProvider.notifier).select(mode);

  Future<void> selectLocale(Locale? locale) =>
      ref.read(localeProvider.notifier).select(locale);

  /// Wipes local data and rebuilds the state derived from it.
  Future<void> clearData() async {
    await ref.read(localDataCleanerProvider).clearAll();
    ref
      ..invalidate(themeModeProvider)
      ..invalidate(localeProvider)
      ..invalidate(postsViewModelProvider);
  }
}

final settingsViewModelProvider =
    NotifierProvider<SettingsViewModel, SettingsState>(
      SettingsViewModel.new,
      isAutoDispose: true,
    );
