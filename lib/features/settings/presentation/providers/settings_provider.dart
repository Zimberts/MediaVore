import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisplayMode { list, grid, swipe }

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  DisplayMode _displayMode = DisplayMode.list;
  double _gridSize = 3.0;
  bool _hideNonReleased = false;

  DisplayMode get displayMode => _displayMode;
  double get gridSize => _gridSize;
  bool get hideNonReleased => _hideNonReleased;

  void _loadSettings() {
    final modeIndex = _prefs.getInt('displayMode') ?? 0;
    _displayMode = DisplayMode.values[modeIndex];
    _gridSize = _prefs.getDouble('gridSize') ?? 3.0;
    _hideNonReleased = _prefs.getBool('hideNonReleased') ?? false;
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
}
