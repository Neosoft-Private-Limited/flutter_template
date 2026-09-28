import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';

void main() {
  Map<String, Object?> readArb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, Object?>;

  Set<String> messageKeys(Map<String, Object?> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  test('every supported locale translates every message', () {
    final template = messageKeys(readArb('en'));

    for (final locale in AppLocalizations.supportedLocales) {
      final keys = messageKeys(readArb(locale.toLanguageTag()));
      expect(
        template.difference(keys),
        isEmpty,
        reason: 'Missing in ${locale.toLanguageTag()}',
      );
      expect(
        keys.difference(template),
        isEmpty,
        reason: 'Unknown keys in ${locale.toLanguageTag()}',
      );
    }
  });

  Future<AppLocalizations> pumpWithLocale(
    WidgetTester tester,
    Locale locale,
  ) async {
    late AppLocalizations strings;
    await tester.pumpWidget(
      Localizations(
        locale: locale,
        delegates: const [
          AppLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Builder(
          builder: (context) {
            strings = context.l10n;
            return const SizedBox();
          },
        ),
      ),
    );
    return strings;
  }

  testWidgets('loads English strings with placeholders', (tester) async {
    final strings = await pumpWithLocale(tester, const Locale('en'));

    expect(strings.appTitle, 'Flutter Template');
    expect(strings.validationTooShort(8), 'Use at least 8 characters');
    expect(strings.postTitle(3), 'Post 3');
  });

  testWidgets('loads Spanish strings', (tester) async {
    final strings = await pumpWithLocale(tester, const Locale('es'));

    expect(strings.navSettings, 'Ajustes');
  });

  test('only supported languages are accepted by the delegate', () {
    expect(AppLocalizations.delegate.isSupported(const Locale('es')), isTrue);
    expect(AppLocalizations.delegate.isSupported(const Locale('fr')), isFalse);
  });
}
