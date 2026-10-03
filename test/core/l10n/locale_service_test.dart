import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late List<Locale> deviceLocales;

  LocaleService build() =>
      LocaleService.withDeviceLocales(prefs, () => deviceLocales);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    deviceLocales = const [Locale('fr', 'FR')];
  });

  group('LocaleService', () {
    test('should follow the device locale without override', () {
      final service = build();
      expect(service.override, isNull);
      expect(service.current.code, 'fr');
      expect(service.tmdbLanguage, 'fr-FR');
    });

    test('should fall back to English on an unsupported device', () {
      deviceLocales = const [Locale('de', 'DE')];
      expect(build().tmdbLanguage, 'en-US');
    });

    test('should persist the override across instances', () async {
      final service = build();
      await service.setOverride(englishLanguage);

      expect(service.tmdbLanguage, 'en-US');
      expect(prefs.getString(LocaleService.overrideKey), 'en');
      expect(build().current.code, 'en');
    });

    test('should follow the device again when override is cleared', () async {
      final service = build();
      await service.setOverride(englishLanguage);
      await service.setOverride(null);

      expect(service.override, isNull);
      expect(service.current.code, 'fr');
      expect(prefs.containsKey(LocaleService.overrideKey), isFalse);
    });

    test('should notify only when the effective language changes', () async {
      final service = build();
      var notifications = 0;
      service.addListener(() => notifications++);

      await service.setOverride(appLanguageForCode('fr')); // same as device
      expect(notifications, 0);

      await service.setOverride(englishLanguage);
      expect(notifications, 1);
    });

    test('should notify when the device locale changes', () {
      final service = build();
      var notifications = 0;
      service.addListener(() => notifications++);

      deviceLocales = const [Locale('en', 'GB')];
      service.handleDeviceLocalesChanged();

      expect(notifications, 1);
      expect(service.tmdbLanguage, 'en-US');
    });

    test('should report the cache as stale until marked', () async {
      final service = build();
      expect(service.isCacheLanguageStale, isTrue);

      await service.markCacheLanguage();
      expect(service.isCacheLanguageStale, isFalse);

      await service.setOverride(englishLanguage);
      expect(service.isCacheLanguageStale, isTrue);
    });
  });
}
