import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisplayMode { list, grid, swipe }

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  DisplayMode _displayMode = DisplayMode.grid;
  double _gridSize = 3.0;
  bool _hideNonReleased = false;

  int _lightAppThemeIndex = 0;
  int _darkAppThemeIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;
  String _tmdbApiKey = '';

  DisplayMode get displayMode => _displayMode;
  double get gridSize => _gridSize;
  bool get hideNonReleased => _hideNonReleased;

  int get lightAppThemeIndex => _lightAppThemeIndex;
  int get darkAppThemeIndex => _darkAppThemeIndex;
  ThemeMode get themeMode => _themeMode;
  String get tmdbApiKey => _tmdbApiKey;

  AppPalette get lightPalette => lightThemes[_lightAppThemeIndex].palette;
  AppPalette get darkPalette => darkThemes[_darkAppThemeIndex].palette;

  void _loadSettings() {
    // Only override the in-memory default if a persisted value exists.
    final int? storedDisplayModeIndex = _prefs.getInt('displayMode');
    if (storedDisplayModeIndex != null) {
      var displayModeIndex = storedDisplayModeIndex;
      if (displayModeIndex < 0 || displayModeIndex >= DisplayMode.values.length) {
        displayModeIndex = 0;
      }
      _displayMode = DisplayMode.values[displayModeIndex];
    }

    _gridSize = _prefs.getDouble('gridSize') ?? 3.0;
    _hideNonReleased = _prefs.getBool('hideNonReleased') ?? false;

    _lightAppThemeIndex = _prefs.getInt('lightAppTheme') ?? 0;
    if (_lightAppThemeIndex < 0 || _lightAppThemeIndex >= lightThemes.length) {
      _lightAppThemeIndex = 0;
    }

    _darkAppThemeIndex = _prefs.getInt('darkAppTheme') ?? 0;
    if (_darkAppThemeIndex < 0 || _darkAppThemeIndex >= darkThemes.length) {
      _darkAppThemeIndex = 0;
    }

    int themeModeIndex = _prefs.getInt('themeMode') ?? 0;
    if (themeModeIndex < 0 || themeModeIndex >= ThemeMode.values.length) {
      themeModeIndex = 0;
    }
    _themeMode = ThemeMode.values[themeModeIndex];

    _tmdbApiKey = _prefs.getString('tmdbApiKey') ?? '';

    notifyListeners();
  }

  Future<void> setTmdbApiKey(String apiKey) async {
    _tmdbApiKey = apiKey;
    await _prefs.setString('tmdbApiKey', apiKey);
    notifyListeners();
  }

  Future<void> setDisplayMode(DisplayMode mode) async {
    _displayMode = mode;
    await _prefs.setInt('displayMode', mode.index);
    notifyListeners();
  }

  Future<void> setGridSize(double size) async {
    _gridSize = size;
    await _prefs.setDouble('gridSize', size);
    notifyListeners();
  }

  Future<void> setHideNonReleased(bool hide) async {
    _hideNonReleased = hide;
    await _prefs.setBool('hideNonReleased', hide);
    notifyListeners();
  }

  Future<void> setLightAppTheme(int themeIndex) async {
    _lightAppThemeIndex = themeIndex;
    await _prefs.setInt('lightAppTheme', themeIndex);
    notifyListeners();
  }

  Future<void> setDarkAppTheme(int themeIndex) async {
    _darkAppThemeIndex = themeIndex;
    await _prefs.setInt('darkAppTheme', themeIndex);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }
}
