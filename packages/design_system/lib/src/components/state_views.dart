import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/tokens/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// A centered progress indicator for loading states.
class AppLoadingView extends StatelessWidget {
  const new({super.key, this.semanticLabel});

  /// Localized label announced by screen readers.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) =>
      Center(child: CircularProgressIndicator(semanticsLabel: semanticLabel));
}

/// A centered icon, title, message and optional action. Used for empty and
/// error states so they look the same everywhere.
class AppMessageView extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
  });

  /// Empty-state preset.
  const factory empty({
    required String title,
    Key? key,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    IconData icon,
  }) = _EmptyMessageView;

  /// Error-state preset, typically with a retry action.
  const factory error({
    required String title,
    Key? key,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    IconData icon,
  }) = _ErrorMessageView;

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppSizes.iconLg,
              color: isError ? colors.error : colors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyMessageView extends AppMessageView {
  const new({
    required super.title,
    super.key,
    super.message,
    super.actionLabel,
    super.onAction,
    super.icon = Icons.inbox_outlined,
  });
}

class _ErrorMessageView extends AppMessageView {
  const new({
    required super.title,
    super.key,
    super.message,
    super.actionLabel,
    super.onAction,
    super.icon = Icons.error_outline,
  }) : super(isError: true);
}

/// A section title inside scrolling content; marked as a heading for screen
/// readers.
class AppSectionHeader extends StatelessWidget {
  const new(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}
