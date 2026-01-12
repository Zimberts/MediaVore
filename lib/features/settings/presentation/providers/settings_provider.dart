import 'package:flutter/material.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:home_widget/home_widget.dart';

enum DisplayMode { list, grid, swipe }

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  DisplayMode _displayMode = DisplayMode.list;
  double _gridSize = 3.0;
  bool _hideNonReleased = false;

  // Restore widget specific settings to unblock build
  String _widgetShelfListName = 'watchlist';
  DisplayMode _widgetShelfDisplayMode = DisplayMode.list;
  bool _widgetShelfHideUnreleased = false;

  int _lightAppThemeIndex = 0;
  int _darkAppThemeIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;

  DisplayMode get displayMode => _displayMode;
  double get gridSize => _gridSize;
  bool get hideNonReleased => _hideNonReleased;

  // Getters for MainPage
  String get widgetShelfListName => _widgetShelfListName;
  DisplayMode get widgetShelfDisplayMode => _widgetShelfDisplayMode;
  bool get widgetShelfHideUnreleased => _widgetShelfHideUnreleased;

  int get lightAppThemeIndex => _lightAppThemeIndex;
  int get darkAppThemeIndex => _darkAppThemeIndex;
  ThemeMode get themeMode => _themeMode;

  AppPalette get lightPalette => lightThemes[_lightAppThemeIndex].palette;
  AppPalette get darkPalette => darkThemes[_darkAppThemeIndex].palette;

  void _loadSettings() {
    int displayModeIndex = _prefs.getInt('displayMode') ?? 0;
    if (displayModeIndex < 0 || displayModeIndex >= DisplayMode.values.length) {
      displayModeIndex = 0;
    }
    _displayMode = DisplayMode.values[displayModeIndex];
    
    _gridSize = _prefs.getDouble('gridSize') ?? 3.0;
    _hideNonReleased = _prefs.getBool('hideNonReleased') ?? false;

    // Load widget settings (legacy/global fallback)
    _widgetShelfListName = _prefs.getString('widgetShelfListName') ?? 'watchlist';
    int wDisplayModeIndex = _prefs.getInt('widgetShelfDisplayMode') ?? 0;
    _widgetShelfDisplayMode = DisplayMode.values[wDisplayModeIndex];
    _widgetShelfHideUnreleased = _prefs.getBool('widgetShelfHideUnreleased') ?? false;

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
    
    notifyListeners();
    _syncThemeToWidget();
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8).toUpperCase()}';
  }

  Future<void> _syncThemeToWidget() async {
    final palette = _themeMode == ThemeMode.light ? lightPalette : darkPalette;
    await HomeWidget.saveWidgetData('theme_primary_bg', _colorToHex(palette.primaryBg));
    await HomeWidget.saveWidgetData('theme_accent', _colorToHex(palette.logicFlow));
    await HomeWidget.saveWidgetData('theme_text_primary', _colorToHex(palette.primaryText));
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
    await _syncThemeToWidget();
    notifyListeners();
  }

  Future<void> setDarkAppTheme(int themeIndex) async {
    _darkAppThemeIndex = themeIndex;
    await _prefs.setInt('darkAppTheme', themeIndex);
    await _syncThemeToWidget();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('themeMode', mode.index);
    await _syncThemeToWidget();
    notifyListeners();
  }
}
