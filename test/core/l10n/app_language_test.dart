import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/app_language.dart';

void main() {
  group('resolveAppLanguage', () {
    test('should pick the device language when supported', () {
      expect(resolveAppLanguage(const [Locale('fr', 'CA')]).code, 'fr');
    });

    test('should pick the first supported language in priority order', () {
      final language = resolveAppLanguage(const [
        Locale('de'),
        Locale('fr'),
        Locale('en'),
      ]);
      expect(language.code, 'fr');
    });

    test('should fall back to English when nothing is supported', () {
      expect(resolveAppLanguage(const [Locale('de')]), fallbackAppLanguage);
      expect(resolveAppLanguage(const []), fallbackAppLanguage);
      expect(fallbackAppLanguage.code, 'en');
    });
  });

  group('supportedAppLanguages', () {
    test('should have unique codes and TMDB tags', () {
      final codes = supportedAppLanguages.map((l) => l.code).toSet();
      final tags = supportedAppLanguages.map((l) => l.tmdbTag).toSet();
      expect(codes.length, supportedAppLanguages.length);
      expect(tags.length, supportedAppLanguages.length);
    });

    test('should map French to fr-FR for TMDB', () {
      expect(appLanguageForCode('fr')?.tmdbTag, 'fr-FR');
      expect(appLanguageForCode('xx'), isNull);
      expect(appLanguageForCode(null), isNull);
    });
  });
}
