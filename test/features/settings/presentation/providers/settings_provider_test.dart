import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late SettingsProvider provider;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();

    // Default mocks for initialization
    when(() => mockPrefs.getInt(any())).thenReturn(null);
    when(() => mockPrefs.getDouble(any())).thenReturn(null);
    when(() => mockPrefs.getBool(any())).thenReturn(null);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

    provider = SettingsProvider(mockPrefs, FakeTmdbCredentialStore());
  });

  group('SettingsProvider - Initialization', () {
    test(
      'should initialize with default values when SharedPreferences is empty',
      () {
        expect(provider.displayMode, DisplayMode.grid);
        expect(provider.gridSize, 3.0);
        expect(provider.themeMode, ThemeMode.system);
        expect(provider.lightAppThemeIndex, 0);
        expect(provider.notificationCenterDebug, false);
      },
    );

    test('should load notificationCenterDebug from SharedPreferences', () {
      when(
        () => mockPrefs.getBool('notificationCenterDebug'),
      ).thenReturn(true);

      final newProvider = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
      );

      expect(newProvider.notificationCenterDebug, true);
    });

    test('should load values from SharedPreferences', () {
      when(() => mockPrefs.getInt('displayMode')).thenReturn(1); // Grid
      when(() => mockPrefs.getDouble('gridSize')).thenReturn(4.0);
      when(() => mockPrefs.getInt('themeMode')).thenReturn(1); // Light

      final newProvider = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
      );

      expect(newProvider.displayMode, DisplayMode.grid);
      expect(newProvider.gridSize, 4.0);
      expect(newProvider.themeMode, ThemeMode.light);
    });
  });

  group('SettingsProvider - Setters', () {
    test(
      'setTmdbApiKey should save to the credential store, not prefs',
      () async {
        final store = FakeTmdbCredentialStore();
        final p = SettingsProvider(mockPrefs, store);

        await p.setTmdbApiKey(' token ');

        expect(store.credential, 'token');
        expect(p.tmdbApiKey, 'token');
        verifyNever(() => mockPrefs.setString(any(), any()));
      },
    );

    test('should load tmdbApiKey from the credential store', () {
      final p = SettingsProvider(mockPrefs, FakeTmdbCredentialStore('k'));

      expect(p.tmdbApiKey, 'k');
    });

    test('setDisplayMode should update state and save to prefs', () async {
      await provider.setDisplayMode(DisplayMode.swipe);

      expect(provider.displayMode, DisplayMode.swipe);
      verify(
        () => mockPrefs.setInt('displayMode', DisplayMode.swipe.index),
      ).called(1);
    });

    test('setGridSize should update state and save to prefs', () async {
      await provider.setGridSize(5.0);

      expect(provider.gridSize, 5.0);
      verify(() => mockPrefs.setDouble('gridSize', 5.0)).called(1);
    });

    test('setThemeMode should update state and save to prefs', () async {
      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      verify(
        () => mockPrefs.setInt('themeMode', ThemeMode.dark.index),
      ).called(1);
    });

    test('setLightAppTheme should update state and save to prefs', () async {
      await provider.setLightAppTheme(2);

      expect(provider.lightAppThemeIndex, 2);
      verify(() => mockPrefs.setInt('lightAppTheme', 2)).called(1);
    });

    test(
      'setNotificationCenterDebug should update state and save to prefs',
      () async {
        await provider.setNotificationCenterDebug(true);

        expect(provider.notificationCenterDebug, true);
        verify(
          () => mockPrefs.setBool('notificationCenterDebug', true),
        ).called(1);
      },
    );
  });

  group('SettingsProvider - Palettes', () {
    test(
      'lightPalette should return the palette corresponding to the current index',
      () async {
        await provider.setLightAppTheme(1); // Parchment
        expect(
          provider.lightPalette.runtimeType.toString(),
          contains('Parchment'),
        );
      },
    );

    test(
      'darkPalette should return the palette corresponding to the current index',
      () async {
        await provider.setDarkAppTheme(1); // Slate
        expect(provider.darkPalette.runtimeType.toString(), contains('Slate'));
      },
    );
  });

  group('SettingsProvider - Language', () {
    late SharedPreferences prefs;
    late LocaleService localeService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      localeService = LocaleService.withDeviceLocales(
        prefs,
        () => const [Locale('de')],
      );
    });

    test('should follow the device by default', () {
      final p = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
        localeService: localeService,
      );
      expect(p.appLanguageOverride, isNull);
      expect(p.locale, isNull);
      expect(localeService.current, fallbackAppLanguage);
    });

    test('should persist the chosen language across restarts', () async {
      final p = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
        localeService: localeService,
      );
      var notified = false;
      p.addListener(() => notified = true);

      await p.setAppLanguage(appLanguageForCode('fr'));

      expect(notified, isTrue);
      expect(p.locale, const Locale('fr'));
      expect(localeService.tmdbLanguage, 'fr-FR');

      final restarted = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
        localeService: LocaleService.withDeviceLocales(
          prefs,
          () => const [Locale('de')],
        ),
      );
      expect(restarted.appLanguageOverride?.code, 'fr');
    });

    test('should go back to the device language on System', () async {
      final p = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
        localeService: localeService,
      );
      await p.setAppLanguage(appLanguageForCode('fr'));
      await p.setAppLanguage(null);

      expect(p.locale, isNull);
      expect(localeService.tmdbLanguage, 'en-US');
    });
  });
}
