import 'package:app/app/error/failure_messages.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:localization/localization.dart';
import 'package:material_ui/material_ui.dart';

/// Neutral showcase of the design system. Replace it with your first feature.
class HomePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: ContentConstraint(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(l10n.homeIntro, style: Theme.of(context).textTheme.bodyLarge),
            AppSectionHeader(l10n.buttonsSection),
            const _ButtonsDemo(),
            AppSectionHeader(l10n.formSection),
            const ExampleForm(),
            AppSectionHeader(l10n.dialogSection),
            const _DialogDemo(),
            AppSectionHeader(l10n.statesSection),
            SizedBox(
              height: 260,
              child: Card(
                child: AppMessageView.empty(
                  title: l10n.postsEmptyTitle,
                  message: l10n.postsEmptyMessage,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 300,
              child: Card(
                child: FailureView(
                  error: const NetworkFailure('demo'),
                  onRetry: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ButtonsDemo extends StatefulWidget {
  const new();

  @override
  State<_ButtonsDemo> createState() => _ButtonsDemoState();
}

class _ButtonsDemoState extends State<_ButtonsDemo> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        AppButton(
          label: l10n.primaryAction,
          isLoading: _loading,
          loadingLabel: l10n.loadingLabel,
          onPressed: () => setState(() => _loading = true),
        ),
        AppButton(
          label: l10n.secondaryAction,
          variant: AppButtonVariant.secondary,
          onPressed: () => setState(() => _loading = false),
        ),
        AppButton(
          label: l10n.textAction,
          variant: AppButtonVariant.text,
          icon: Icons.info_outline,
          onPressed: () {},
        ),
      ],
    );
  }
}

/// Form validation with pure validators from `core` and localized messages.
class ExampleForm extends StatefulWidget {
  const new({super.key});

  static const minPasswordLength = 8;

  @override
  State<ExampleForm> createState() => _ExampleFormState();
}

class _ExampleFormState extends State<ExampleForm> {
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      showAppSnackBar(context, context.l10n.formValid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: l10n.emailLabel,
              hint: l10n.emailHint,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) => switch (Validators.email(value)) {
                final error? => l10n.describeValidation(error),
                null => null,
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.passwordLabel,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              validator: (value) => switch (Validators.minLength(
                value,
                ExampleForm.minPasswordLength,
              )) {
                final error? => l10n.describeValidation(
                  error,
                  minLength: ExampleForm.minPasswordLength,
                ),
                null => null,
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: l10n.submitAction, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

class _DialogDemo extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: AppButton(
        label: l10n.showDialogAction,
        variant: AppButtonVariant.secondary,
        onPressed: () async {
          final confirmed = await showAppConfirmDialog(
            context,
            title: l10n.dialogTitle,
            message: l10n.dialogMessage,
            confirmLabel: l10n.confirmAction,
            cancelLabel: l10n.cancelAction,
          );
          if (context.mounted) {
            showAppSnackBar(
              context,
              confirmed ? l10n.dialogConfirmed : l10n.dialogCancelled,
            );
          }
        },
      ),
    );
  }
}
