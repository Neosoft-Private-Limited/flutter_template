import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Stateless settings screen body: theme, language, build information and
/// clearing local data. Apps pass the current values and callbacks from
/// their state management.
class SettingsView extends StatelessWidget {
  /// Creates the settings body from the current values and callbacks.
  const new({
    required this.config,
    required this.themeMode,
    required this.locale,
    required this.onThemeModeChanged,
    required this.onLocaleChanged,
    required this.onClearData,
    super.key,
  });

  /// Build configuration shown in the about section (environment, API and
  /// GraphQL hosts).
  final AppConfig config;

  /// The selected theme mode.
  final ThemeMode themeMode;

  /// `null` follows the device language.
  final Locale? locale;

  /// Called when the user picks a different theme mode.
  final ValueChanged<ThemeMode> onThemeModeChanged;

  /// Called when the user picks a language; `null` means follow the device.
  final ValueChanged<Locale?> onLocaleChanged;

  /// Clears local data. Called only after the user confirms.
  final Future<void> Function() onClearData;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ContentConstraint(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          AppSectionHeader(l10n.themeSection),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.themeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.themeLight),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.themeDark),
                icon: const Icon(Icons.dark_mode),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) =>
                onThemeModeChanged(selection.single),
          ),
          AppSectionHeader(l10n.languageSection),
          RadioGroup<String>(
            groupValue: locale?.languageCode ?? '',
            onChanged: (code) => onLocaleChanged(
              code == null || code.isEmpty ? null : Locale(code),
            ),
            child: Column(
              children: [
                RadioListTile(value: '', title: Text(l10n.languageSystem)),
                RadioListTile(value: 'en', title: Text(l10n.languageEnglish)),
                RadioListTile(value: 'es', title: Text(l10n.languageSpanish)),
              ],
            ),
          ),
          AppSectionHeader(l10n.aboutSection),
          _InfoRow(
            label: l10n.environmentLabel,
            value: config.environment.name,
          ),
          _InfoRow(label: l10n.apiLabel, value: config.apiBaseUrl.host),
          if (config.graphQLUrl case final url?)
            _InfoRow(label: l10n.graphQLLabel, value: url.host),
          AppSectionHeader(l10n.dataSection),
          Text(l10n.clearDataMessage),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              label: l10n.clearDataAction,
              icon: Icons.delete_outline,
              variant: AppButtonVariant.secondary,
              onPressed: () => _clearData(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _clearData(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.clearDataAction,
      message: l10n.clearDataMessage,
      confirmLabel: l10n.confirmAction,
      cancelLabel: l10n.cancelAction,
      destructive: true,
    );
    if (!confirmed) return;
    await onClearData();
    if (context.mounted) showAppSnackBar(context, l10n.clearDataDone);
  }
}

class _InfoRow extends StatelessWidget {
  const new({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(value),
  );
}
