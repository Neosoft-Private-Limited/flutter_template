import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  group('AppButton', () {
    testWidgets('invokes onPressed', (tester) async {
      var taps = 0;
      await pumpThemed(tester, AppButton(label: 'Go', onPressed: () => taps++));

      await tester.tap(find.text('Go'));

      expect(taps, 1);
    });

    testWidgets('renders each variant with the matching Material button', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        Column(
          children: [
            AppButton(label: 'a', onPressed: () {}),
            AppButton(
              label: 'b',
              onPressed: () {},
              variant: AppButtonVariant.secondary,
            ),
            AppButton(
              label: 'c',
              onPressed: () {},
              variant: AppButtonVariant.text,
            ),
          ],
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('is disabled and announces progress while loading', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpThemed(
        tester,
        AppButton(
          label: 'Save',
          onPressed: () => taps++,
          isLoading: true,
          loadingLabel: 'Saving',
        ),
      );

      await tester.tap(find.byType(AppButton));

      expect(taps, 0);
      expect(find.text('Save'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Saving'), findsWidgets);
      handle.dispose();
    });
  });

  group('AppTextField', () {
    testWidgets('shows the validator message after submission', (tester) async {
      final formKey = GlobalKey<FormState>();
      await pumpThemed(
        tester,
        Form(
          key: formKey,
          child: AppTextField(
            label: 'Email',
            validator: (value) => (value ?? '').isEmpty ? 'Required' : null,
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'a@b.co');
      await tester.pump();
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Required'), findsNothing);
    });

    testWidgets('exposes its label to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemed(tester, const AppTextField(label: 'Password'));

      expect(find.bySemanticsLabel('Password'), findsOneWidget);
      handle.dispose();
    });
  });

  group('showAppConfirmDialog', () {
    testWidgets('resolves to true only when confirmed', (tester) async {
      late Future<bool> pending;
      await pumpThemed(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => pending = showAppConfirmDialog(
              context,
              title: 'T',
              message: 'M',
              confirmLabel: 'Yes',
              cancelLabel: 'No',
            ),
            child: const Text('open'),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(await pending, isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(await pending, isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(await pending, isTrue);
    });
  });

  group('state views', () {
    testWidgets('error view renders its retry action', (tester) async {
      var retries = 0;
      await pumpThemed(
        tester,
        AppMessageView.error(
          title: 'Offline',
          message: 'Check your connection',
          actionLabel: 'Retry',
          onAction: () => retries++,
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Check your connection'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('empty view hides the action without a callback', (
      tester,
    ) async {
      await pumpThemed(
        tester,
        const AppMessageView.empty(title: 'Nothing here', actionLabel: 'Add'),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('Add'), findsNothing);
    });

    testWidgets('loading view exposes its semantic label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpThemed(tester, const AppLoadingView(semanticLabel: 'Loading'));

      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('supports large text scaling without overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpThemed(
        tester,
        const AppMessageView.error(
          title: 'A fairly long error title that wraps',
          message: 'A longer explanation that should wrap across lines.',
        ),
        size: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
