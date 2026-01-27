import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
  });

  test('SettingsProvider initializes from SharedPreferences', () {
    when(() => mockPrefs.getInt('themeMode')).thenReturn(1);
    when(() => mockPrefs.getInt('lightAppTheme')).thenReturn(0);
    when(() => mockPrefs.getInt('darkAppTheme')).thenReturn(0);
    when(() => mockPrefs.getInt('displayMode')).thenReturn(0);
    when(() => mockPrefs.getDouble('gridSize')).thenReturn(3.0);
    when(() => mockPrefs.getBool('hideNonReleased')).thenReturn(false);

    final provider = SettingsProvider(mockPrefs);
    expect(provider.themeMode, equals(ThemeMode.values[1]));
    expect(provider.gridSize, equals(3.0));
    expect(provider.displayMode, equals(DisplayMode.list));
  });

  test('setThemeMode updates prefs and notifies', () async {
    when(() => mockPrefs.getInt('themeMode')).thenReturn(0);
    when(
      () => mockPrefs.setInt('themeMode', any()),
    ).thenAnswer((_) async => true);

    final provider = SettingsProvider(mockPrefs);
    await provider.setThemeMode(ThemeMode.dark);

    expect(provider.themeMode, equals(ThemeMode.dark));
    verify(() => mockPrefs.setInt('themeMode', ThemeMode.dark.index)).called(1);
  });
}
