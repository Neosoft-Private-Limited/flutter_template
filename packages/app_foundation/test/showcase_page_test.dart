import 'package:app_foundation/app_foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/pump.dart';

void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label).first;

  Future<void> submit(WidgetTester tester) =>
      scrollToAndTap(tester, find.text('Submit'));

  testWidgets('form shows localized validation errors', (tester) async {
    await pumpLocalized(tester, const ShowcasePage());

    await submit(tester);

    expect(find.text('This field is required'), findsNWidgets(2));
  });

  testWidgets('form validates email format and password length', (
    tester,
  ) async {
    await pumpLocalized(tester, const ShowcasePage());
    await tester.ensureVisible(field('Email'));

    await tester.enterText(field('Email'), 'not-an-email');
    await tester.enterText(field('Password'), 'short');
    await submit(tester);

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
  });

  testWidgets('valid form shows a confirmation', (tester) async {
    await pumpLocalized(tester, const ShowcasePage());
    await tester.ensureVisible(field('Email'));

    await tester.enterText(field('Email'), 'person@acme.dev');
    await tester.enterText(field('Password'), 'long-enough');
    await submit(tester);

    expect(find.text('Form is valid'), findsOneWidget);
  });

  testWidgets('dialog reports the choice', (tester) async {
    await pumpLocalized(tester, const ShowcasePage());

    await scrollToAndTap(tester, find.text('Show dialog'));
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmed'), findsOneWidget);
  });

  testWidgets('meets tap target and labelling guidelines', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpLocalized(tester, const ShowcasePage());

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
