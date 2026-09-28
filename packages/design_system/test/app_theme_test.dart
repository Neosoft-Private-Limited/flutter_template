import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers.dart';

void main() {
  group('AppTheme', () {
    test('builds Material 3 light and dark schemes from the seed', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.useMaterial3, isTrue);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));
    });

    test('keeps interactive elements at least 48dp tall', () {
      final theme = AppTheme.light();

      for (final style in [
        theme.filledButtonTheme.style,
        theme.outlinedButtonTheme.style,
        theme.textButtonTheme.style,
      ]) {
        final minimum = style!.minimumSize!.resolve({})!;
        expect(minimum.height, greaterThanOrEqualTo(AppSizes.minTouchTarget));
      }
      expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    });

    for (final brightness in Brightness.values) {
      testWidgets('meets accessibility guidelines in ${brightness.name} mode', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpThemed(
          tester,
          Column(
            children: [
              const AppSectionHeader('Section'),
              AppButton(label: 'Primary', onPressed: () {}),
              AppButton(
                label: 'Secondary',
                onPressed: () {},
                variant: AppButtonVariant.secondary,
              ),
              AppButton(
                label: 'Text',
                onPressed: () {},
                variant: AppButtonVariant.text,
              ),
              const Expanded(
                child: AppMessageView.error(title: 'Title', message: 'Body'),
              ),
            ],
          ),
          brightness: brightness,
        );

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });
}
