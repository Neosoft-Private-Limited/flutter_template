import 'dart:async';

import 'package:app_bloc/features/settings/cubit/settings_cubits.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';

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

  @override
  bool operator ==(Object other) =>
      other is SettingsState &&
      identical(other.config, config) &&
      other.themeMode == themeMode &&
      other.locale == locale;

  @override
  int get hashCode => Object.hash(config, themeMode, locale);
}

/// View model of the settings screen. Theme and locale are app-wide
/// ([ThemeCubit], [LocaleCubit] drive `MaterialApp`); this cubit mirrors
/// them for the screen and exposes the screen's intents.
class SettingsCubit extends Cubit<SettingsState> {
  new({
    required AppConfig config,
    required this._themeCubit,
    required this._localeCubit,
    required this._localDataCleaner,
  }) : super(
         SettingsState(
           config: config,
           themeMode: _themeCubit.state,
           locale: _localeCubit.state,
         ),
       ) {
    _subscriptions = [
      _themeCubit.stream.listen((mode) => emit(_copy(themeMode: mode))),
      _localeCubit.stream.listen(
        (locale) => emit(_copy(locale: locale, localeChanged: true)),
      ),
    ];
  }

  final ThemeCubit _themeCubit;
  final LocaleCubit _localeCubit;
  final LocalDataCleaner _localDataCleaner;
  late final List<StreamSubscription<Object?>> _subscriptions;

  Future<void> selectThemeMode(ThemeMode mode) => _themeCubit.select(mode);

  Future<void> selectLocale(Locale? locale) => _localeCubit.select(locale);

  /// Wipes local data and reloads the state derived from it.
  Future<void> clearData() async {
    await _localDataCleaner.clearAll();
    _themeCubit.reload();
    _localeCubit.reload();
  }

  SettingsState _copy({
    ThemeMode? themeMode,
    Locale? locale,
    bool localeChanged = false,
  }) => SettingsState(
    config: state.config,
    themeMode: themeMode ?? state.themeMode,
    locale: localeChanged ? locale : state.locale,
  );

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await super.close();
  }
}
