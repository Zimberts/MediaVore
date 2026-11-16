import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/theme/app_palette.dart';
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
    when(() => mockPrefs.getString(any())).thenReturn(null);
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);

    provider = SettingsProvider(mockPrefs, FakeTmdbCredentialStore());
  });

  group('SettingsProvider - Initialization', () {
    test(
      'should initialize with default values when SharedPreferences is empty',
      () {
        expect(provider.displayMode, DisplayMode.grid);
        expect(provider.gridSize, 3.0);
        expect(provider.themeMode, ThemeMode.system);
        expect(provider.lightPalette, AppPalette.paper);
        expect(provider.darkPalette, AppPalette.ink);
        expect(provider.notificationCenterDebug, false);
        expect(provider.advancedTracking, false);
        expect(provider.previousEpisodes, PreviousEpisodesBehavior.ask);
        expect(provider.watchProvidersCountry, isNull);
      },
    );

    test('should load notificationCenterDebug from SharedPreferences', () {
      when(() => mockPrefs.getBool('notificationCenterDebug')).thenReturn(true);

      final newProvider = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
      );

      expect(newProvider.notificationCenterDebug, true);
    });

    test('should load advancedTracking from SharedPreferences', () {
      when(
        () => mockPrefs.getBool(SettingsProvider.advancedTrackingKey),
      ).thenReturn(true);

      final newProvider = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
      );

      expect(newProvider.advancedTracking, true);
    });

    test('should load previousEpisodes from SharedPreferences', () {
      when(
        () => mockPrefs.getString(SettingsProvider.previousEpisodesKey),
      ).thenReturn('all');

      final newProvider = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
      );

      expect(newProvider.previousEpisodes, PreviousEpisodesBehavior.all);
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
      await provider.setDisplayMode(DisplayMode.list);

      expect(provider.displayMode, DisplayMode.list);
      verify(
        () => mockPrefs.setInt('displayMode', DisplayMode.list.index),
      ).called(1);

      // v1.4.0 swipe mode falls back to grid
      await provider.setDisplayMode(DisplayMode.swipe);
      expect(provider.displayMode, DisplayMode.grid);
      verify(
        () => mockPrefs.setInt('displayMode', DisplayMode.grid.index),
      ).called(1);
    });

    test('setGridSize should update state and save to prefs', () async {
      await provider.setGridSize(3.0);

      expect(provider.gridSize, 3.0);
      verify(() => mockPrefs.setDouble('gridSize', 3.0)).called(1);

      // Clamps outside [2.0, 4.0]
      await provider.setGridSize(5.0);
      expect(provider.gridSize, 4.0);
      verify(() => mockPrefs.setDouble('gridSize', 4.0)).called(1);
    });

    test('setThemeMode should update state and save to prefs', () async {
      await provider.setThemeMode(ThemeMode.dark);

      expect(provider.themeMode, ThemeMode.dark);
      verify(
        () => mockPrefs.setInt('themeMode', ThemeMode.dark.index),
      ).called(1);
    });

    test('setLightPalette should update state and save its id', () async {
      await provider.setLightPalette(AppPaletteId.mist);

      expect(provider.lightPalette, AppPalette.mist);
      verify(() => mockPrefs.setString('lightPalette', 'mist')).called(1);
    });

    test('setDarkPalette should update state and save its id', () async {
      await provider.setDarkPalette(AppPaletteId.oled);

      expect(provider.darkPalette, AppPalette.oled);
      verify(() => mockPrefs.setString('darkPalette', 'oled')).called(1);
    });

    test('should ignore a palette of the other brightness', () async {
      await provider.setLightPalette(AppPaletteId.night);
      await provider.setDarkPalette(AppPaletteId.sand);

      expect(provider.lightPalette, AppPalette.paper);
      expect(provider.darkPalette, AppPalette.ink);
      verifyNever(() => mockPrefs.setString(any(), any()));
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

    test('setAdvancedTracking should update state and save to prefs', () async {
      await provider.setAdvancedTracking(true);

      expect(provider.advancedTracking, true);
      verify(
        () => mockPrefs.setBool(SettingsProvider.advancedTrackingKey, true),
      ).called(1);
    });

    test('setPreviousEpisodes should update state and save to prefs', () async {
      await provider.setPreviousEpisodes(PreviousEpisodesBehavior.one);

      expect(provider.previousEpisodes, PreviousEpisodesBehavior.one);
      verify(
        () => mockPrefs.setString(SettingsProvider.previousEpisodesKey, 'one'),
      ).called(1);
    });
  });

  group('SettingsProvider - Palettes', () {
    SettingsProvider build() =>
        SettingsProvider(mockPrefs, FakeTmdbCredentialStore());

    test('should load the palettes stored by identifier', () {
      when(() => mockPrefs.getString('lightPalette')).thenReturn('sand');
      when(() => mockPrefs.getString('darkPalette')).thenReturn('night');

      final loaded = build();

      expect(loaded.lightPalette, AppPalette.sand);
      expect(loaded.darkPalette, AppPalette.night);
    });

    test('should fall back to the defaults on an unknown identifier', () {
      when(() => mockPrefs.getString('lightPalette')).thenReturn('unknown_theme');
      when(() => mockPrefs.getString('darkPalette')).thenReturn('');

      final loaded = build();

      expect(loaded.lightPalette, AppPalette.paper);
      expect(loaded.darkPalette, AppPalette.ink);
    });

    test('should fall back to the default when the stored palette has the '
        'other brightness', () {
      when(() => mockPrefs.getString('lightPalette')).thenReturn('oled');
      when(() => mockPrefs.getString('darkPalette')).thenReturn('paper');

      final loaded = build();

      expect(loaded.lightPalette, AppPalette.paper);
      expect(loaded.darkPalette, AppPalette.ink);
    });
  });

  group('SettingsProvider - Migration from v1.3.0', () {
    // v1.3.0 stored an index into lists of palettes that no longer exist:
    // light 0..4 (Default, Parchment, Mint, Solarized, Pinky),
    // dark 0..3 (Default, Slate, Midnight, Espresso).
    Future<SettingsProvider> buildWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final prefs = await SharedPreferences.getInstance();
      return SettingsProvider(prefs, FakeTmdbCredentialStore());
    }

    test('should start on the default palettes with a custom legacy '
        'palette', () async {
      for (var light = 0; light < 5; light++) {
        for (var dark = 0; dark < 4; dark++) {
          final migrated = await buildWith({
            'lightAppTheme': light,
            'darkAppTheme': dark,
          });

          expect(migrated.lightPalette, AppPalette.paper);
          expect(migrated.darkPalette, AppPalette.ink);
        }
      }
    });

    test('should start on the default palettes with an out-of-range legacy '
        'index', () async {
      final migrated = await buildWith({
        'lightAppTheme': 42,
        'darkAppTheme': -1,
      });

      expect(migrated.lightPalette, AppPalette.paper);
      expect(migrated.darkPalette, AppPalette.ink);
    });

    test('should keep the other settings and leave the legacy keys '
        'untouched', () async {
      final migrated = await buildWith({
        'lightAppTheme': 4,
        'darkAppTheme': 3,
        'themeMode': ThemeMode.dark.index,
        'gridSize': 4.0,
      });
      final prefs = await SharedPreferences.getInstance();

      expect(migrated.themeMode, ThemeMode.dark);
      expect(migrated.gridSize, 4.0);
      expect(prefs.getInt('lightAppTheme'), 4);
      expect(prefs.getInt('darkAppTheme'), 3);
      expect(migrated.lightPalette.toThemeData().brightness, Brightness.light);
      expect(migrated.darkPalette.toThemeData().brightness, Brightness.dark);
    });

    test('should persist a palette picked after the migration', () async {
      final migrated = await buildWith({'lightAppTheme': 2});
      await migrated.setLightPalette(AppPaletteId.sand);

      final prefs = await SharedPreferences.getInstance();
      final reloaded = SettingsProvider(prefs, FakeTmdbCredentialStore());

      expect(prefs.getString('lightPalette'), 'sand');
      expect(reloaded.lightPalette, AppPalette.sand);
    });
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
  });

  group('SettingsProvider - Watch Providers Country', () {
    test('should load watchProvidersCountry from SharedPreferences', () {
      when(
        () => mockPrefs.getString(SettingsProvider.watchProvidersCountryKey),
      ).thenReturn('FR');

      final newProvider = SettingsProvider(
        mockPrefs,
        FakeTmdbCredentialStore(),
      );

      expect(newProvider.watchProvidersCountry, equals('FR'));
    });

    test('should set and persist watchProvidersCountry', () async {
      when(
        () => mockPrefs.setString(
          SettingsProvider.watchProvidersCountryKey,
          'US',
        ),
      ).thenAnswer((_) async => true);

      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setWatchProvidersCountry('us');

      expect(provider.watchProvidersCountry, equals('US'));
      expect(notified, isTrue);
      verify(
        () => mockPrefs.setString(
          SettingsProvider.watchProvidersCountryKey,
          'US',
        ),
      ).called(1);
    });

    test('should remove watchProvidersCountry when null or empty', () async {
      when(
        () => mockPrefs.remove(SettingsProvider.watchProvidersCountryKey),
      ).thenAnswer((_) async => true);

      await provider.setWatchProvidersCountry(null);

      expect(provider.watchProvidersCountry, isNull);
      verify(
        () => mockPrefs.remove(SettingsProvider.watchProvidersCountryKey),
      ).called(1);
    });

    test('resolveWatchProvidersCountry resolves override if set', () async {
      when(
        () => mockPrefs.setString(
          SettingsProvider.watchProvidersCountryKey,
          'CA',
        ),
      ).thenAnswer((_) async => true);
      await provider.setWatchProvidersCountry('CA');

      expect(
        provider.resolveWatchProvidersCountry(const Locale('fr', 'FR')),
        equals('CA'),
      );
    });

    test(
      'resolveWatchProvidersCountry resolves device locale country if no override',
      () {
        expect(
          provider.resolveWatchProvidersCountry(const Locale('en', 'GB')),
          equals('GB'),
        );
      },
    );
  });
}
