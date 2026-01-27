import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import '../../helpers/mocks.dart';

void main() {
  group('SettingsProvider persistence', () {
    late MockSharedPreferences mockPrefs;
    late SettingsProvider provider;

    setUp(() {
      mockPrefs = MockSharedPreferences();

      when(() => mockPrefs.getInt(any())).thenReturn(null);
      when(() => mockPrefs.getDouble(any())).thenReturn(null);
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      // Mock set* methods to return a successful Future<bool>
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(
        () => mockPrefs.setDouble(any(), any()),
      ).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      provider = SettingsProvider(mockPrefs);
    });

    test('setDisplayMode writes to shared prefs', () async {
      await provider.setDisplayMode(DisplayMode.grid);
      verify(
        () => mockPrefs.setInt('displayMode', DisplayMode.grid.index),
      ).called(1);
      expect(provider.displayMode, DisplayMode.grid);
    });

    test('setGridSize writes to shared prefs', () async {
      await provider.setGridSize(4.0);
      verify(() => mockPrefs.setDouble('gridSize', 4.0)).called(1);
      expect(provider.gridSize, 4.0);
    });

    test('setHideNonReleased writes to shared prefs', () async {
      await provider.setHideNonReleased(true);
      verify(() => mockPrefs.setBool('hideNonReleased', true)).called(1);
      expect(provider.hideNonReleased, isTrue);
    });

    test('setThemeMode writes to shared prefs', () async {
      await provider.setThemeMode(ThemeMode.light);
      verify(
        () => mockPrefs.setInt('themeMode', ThemeMode.light.index),
      ).called(1);
      expect(provider.themeMode, ThemeMode.light);
    });
  });
}
