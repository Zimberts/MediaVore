import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisplayMode { list, grid, swipe }

class SettingsProvider with ChangeNotifier {
  /// Preference keys of the selected palettes (stable identifiers).
  static const String lightPaletteKey = 'lightPalette';
  static const String darkPaletteKey = 'darkPalette';

  final SharedPreferences _prefs;
  final TmdbCredentialStore _credentials;
  final LocaleService? _localeService;

  SettingsProvider(
    this._prefs,
    this._credentials, {
    LocaleService? localeService,
  }) : _localeService = localeService {
    _loadSettings();
  }

  DisplayMode _displayMode = DisplayMode.grid;
  double _gridSize = 3.0;
  bool _hideNonReleased = false;
  bool _notificationCenterDebug = false;

  AppPalette _lightPalette = AppPalette.defaultLight;
  AppPalette _darkPalette = AppPalette.defaultDark;
  ThemeMode _themeMode = ThemeMode.system;
  String _tmdbApiKey = '';

  DisplayMode get displayMode => _displayMode;
  double get gridSize => _gridSize;
  bool get hideNonReleased => _hideNonReleased;
  bool get notificationCenterDebug => _notificationCenterDebug;

  ThemeMode get themeMode => _themeMode;
  String get tmdbApiKey => _tmdbApiKey;

  /// Language picked in Settings, or `null` to follow the device.
  AppLanguage? get appLanguageOverride => _localeService?.override;

  /// Locale forced on the app, or `null` to let Flutter follow the device.
  Locale? get locale => appLanguageOverride?.locale;

  AppPalette get lightPalette => _lightPalette;
  AppPalette get darkPalette => _darkPalette;

  void _loadSettings() {
    // Only override the in-memory default if a persisted value exists.
    final int? storedDisplayModeIndex = _prefs.getInt('displayMode');
    if (storedDisplayModeIndex != null) {
      var displayModeIndex = storedDisplayModeIndex;
      if (displayModeIndex < 0 ||
          displayModeIndex >= DisplayMode.values.length) {
        displayModeIndex = 0;
      }
      _displayMode = DisplayMode.values[displayModeIndex];
    }

    _gridSize = _prefs.getDouble('gridSize') ?? 3.0;
    _hideNonReleased = _prefs.getBool('hideNonReleased') ?? false;
    _notificationCenterDebug =
        _prefs.getBool('notificationCenterDebug') ?? false;

    // Palettes are stored by stable identifier. Up to v1.3.0 they were
    // stored as an index (`lightAppTheme` / `darkAppTheme`) into lists of
    // palettes that no longer exist: those keys are neither read nor
    // deleted, so such an install starts on the default palettes.
    _lightPalette = AppPalette.fromStorageId(
      _prefs.getString(lightPaletteKey),
      Brightness.light,
    );
    _darkPalette = AppPalette.fromStorageId(
      _prefs.getString(darkPaletteKey),
      Brightness.dark,
    );

    int themeModeIndex = _prefs.getInt('themeMode') ?? 0;
    if (themeModeIndex < 0 || themeModeIndex >= ThemeMode.values.length) {
      themeModeIndex = 0;
    }
    _themeMode = ThemeMode.values[themeModeIndex];

    _tmdbApiKey = _credentials.credential;

    notifyListeners();
  }

  Future<void> setTmdbApiKey(String apiKey) async {
    await _credentials.save(apiKey);
    _tmdbApiKey = _credentials.credential;
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

  Future<void> setNotificationCenterDebug(bool enabled) async {
    _notificationCenterDebug = enabled;
    await _prefs.setBool('notificationCenterDebug', enabled);
    notifyListeners();
  }

  /// Selects the palette used in light mode. Ignores a dark palette.
  Future<void> setLightPalette(AppPaletteId id) async {
    if (id.brightness != Brightness.light) return;
    _lightPalette = AppPalette.of(id);
    await _prefs.setString(lightPaletteKey, id.name);
    notifyListeners();
  }

  /// Selects the palette used in dark mode. Ignores a light palette.
  Future<void> setDarkPalette(AppPaletteId id) async {
    if (id.brightness != Brightness.dark) return;
    _darkPalette = AppPalette.of(id);
    await _prefs.setString(darkPaletteKey, id.name);
    notifyListeners();
  }

  /// Forces the app language; `null` follows the device locale again.
  Future<void> setAppLanguage(AppLanguage? language) async {
    final localeService = _localeService;
    if (localeService == null) return;
    await localeService.setOverride(language);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }
}
