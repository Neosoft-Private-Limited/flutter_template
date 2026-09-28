import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Shown instead of the app when the build configuration is invalid, so a
/// misconfigured build fails immediately and visibly rather than later with a
/// confusing network error.
///
/// This is a developer-facing screen (end users never see a correctly
/// configured build fail), so it is intentionally not localized.
class ConfigErrorApp extends StatelessWidget {
  const new(this.exception, {super.key});

  final ConfigException exception;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    home: Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Icon(
              Icons.settings_suggest_outlined,
              size: AppSizes.iconLg,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Invalid build configuration',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final problem in exception.problems)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('- $problem'),
              ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Run with --flavor <env> '
              '--dart-define-from-file=config/<env>.json. '
              'See docs/environment-configuration.md.',
            ),
          ],
        ),
      ),
    ),
  );
}
