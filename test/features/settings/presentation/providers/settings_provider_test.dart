import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:mocktail/mocktail.dart';
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

    provider = SettingsProvider(mockPrefs);
  });

  group('SettingsProvider - Initialization', () {
    test(
      'should initialize with default values when SharedPreferences is empty',
      () {
        expect(provider.displayMode, DisplayMode.list);
        expect(provider.gridSize, 3.0);
        expect(provider.themeMode, ThemeMode.system);
        expect(provider.lightAppThemeIndex, 0);
      },
    );

    test('should load values from SharedPreferences', () {
      when(() => mockPrefs.getInt('displayMode')).thenReturn(1); // Grid
      when(() => mockPrefs.getDouble('gridSize')).thenReturn(4.0);
      when(() => mockPrefs.getInt('themeMode')).thenReturn(1); // Light

      final newProvider = SettingsProvider(mockPrefs);

      expect(newProvider.displayMode, DisplayMode.grid);
      expect(newProvider.gridSize, 4.0);
      expect(newProvider.themeMode, ThemeMode.light);
    });
  });

  group('SettingsProvider - Setters', () {
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
}
