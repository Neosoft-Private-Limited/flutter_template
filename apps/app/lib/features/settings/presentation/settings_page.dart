import 'package:app/app/base/base_page.dart';
import 'package:app/features/settings/presentation/settings_view_model.dart';
import 'package:app_foundation/app_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Connects the shared [SettingsView] to [SettingsViewModel].
class SettingsPage extends BasePage<SettingsViewModel, SettingsState> {
  const new({super.key});

  @override
  NotifierProvider<SettingsViewModel, SettingsState> get viewModelProvider =>
      settingsViewModelProvider;

  @override
  String title(BuildContext context) => context.l10n.settingsTitle;

  @override
  Widget buildView(
    BuildContext context,
    SettingsState state,
    SettingsViewModel viewModel,
  ) => SettingsView(
    config: state.config,
    themeMode: state.themeMode,
    locale: state.locale,
    onThemeModeChanged: viewModel.selectThemeMode,
    onLocaleChanged: viewModel.selectLocale,
    onClearData: viewModel.clearData,
  );
}
