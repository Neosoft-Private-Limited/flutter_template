import 'package:app_bloc/app/base/base_page.dart';
import 'package:app_bloc/features/settings/cubit/settings_cubit.dart';
import 'package:app_bloc/features/settings/cubit/settings_cubits.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Connects the shared [SettingsView] to [SettingsCubit].
class SettingsPage extends BasePage<SettingsCubit, SettingsState> {
  const new({super.key});

  @override
  SettingsCubit createViewModel(BuildContext context) => SettingsCubit(
    config: context.read<AppConfig>(),
    themeCubit: context.read<ThemeCubit>(),
    localeCubit: context.read<LocaleCubit>(),
    localDataCleaner: context.read<LocalDataCleaner>(),
  );

  @override
  String title(BuildContext context) => context.l10n.settingsTitle;

  @override
  Widget buildView(
    BuildContext context,
    SettingsState state,
    SettingsCubit viewModel,
  ) => SettingsView(
    config: state.config,
    themeMode: state.themeMode,
    locale: state.locale,
    onThemeModeChanged: viewModel.selectThemeMode,
    onLocaleChanged: viewModel.selectLocale,
    onClearData: viewModel.clearData,
  );
}
