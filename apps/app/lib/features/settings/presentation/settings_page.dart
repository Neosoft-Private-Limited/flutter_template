import 'package:app/app/di/providers.dart';
import 'package:app/features/posts/presentation/posts_providers.dart';
import 'package:app/features/settings/presentation/settings_controllers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

class SettingsPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(appConfigProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ContentConstraint(
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
                  ref.read(themeModeProvider.notifier).select(selection.single),
            ),
            AppSectionHeader(l10n.languageSection),
            RadioGroup<String>(
              groupValue: locale?.languageCode ?? '',
              onChanged: (code) => ref
                  .read(localeProvider.notifier)
                  .select(code == null || code.isEmpty ? null : Locale(code)),
              child: Column(
                children: [
                  RadioListTile(value: '', title: Text(l10n.languageSystem)),
                  RadioListTile(value: 'en', title: Text(l10n.languageEnglish)),
                  RadioListTile(value: 'es', title: Text(l10n.languageSpanish)),
                ],
              ),
            ),
            AppSectionHeader(l10n.aboutSection),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.environmentLabel),
              trailing: Text(config.environment.name),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.apiLabel),
              trailing: Text(config.apiBaseUrl.host),
            ),
            AppSectionHeader(l10n.dataSection),
            Text(l10n.clearDataMessage),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: l10n.clearDataAction,
                icon: Icons.delete_outline,
                variant: AppButtonVariant.secondary,
                onPressed: () => _clearData(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
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

    await ref.read(localDataCleanerProvider).clearAll();
    // Rebuild state that was derived from the cleared data.
    ref
      ..invalidate(themeModeProvider)
      ..invalidate(localeProvider)
      ..invalidate(postsControllerProvider);
    if (context.mounted) showAppSnackBar(context, l10n.clearDataDone);
  }
}
