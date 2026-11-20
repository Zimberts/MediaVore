import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/core/l10n/locale_service.dart';
import 'package:mediavore/core/security/tmdb_credential_store.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DisplayMode { list, grid, swipe }

enum PreviousEpisodesBehavior { ask, all, one }

class SettingsProvider with ChangeNotifier {
  /// Preference keys of the selected palettes (stable identifiers).
  static const String lightPaletteKey = 'lightPalette';
  static const String darkPaletteKey = 'darkPalette';
  static const String advancedTrackingKey = 'advancedTracking';
  static const String previousEpisodesKey = 'previousEpisodes';
  static const String watchProvidersCountryKey = 'watchProvidersCountry';
  static const String swipeModeEnabledKey = 'swipeModeEnabled';

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
  bool _advancedTracking = false;
  PreviousEpisodesBehavior _previousEpisodes = PreviousEpisodesBehavior.ask;
  String? _watchProvidersCountry;
  bool _swipeModeEnabled = true;
  String _swipeTargetList = 'watchlist';

  AppPalette _lightPalette = AppPalette.defaultLight;
  AppPalette _darkPalette = AppPalette.defaultDark;
  ThemeMode _themeMode = ThemeMode.system;
  String _tmdbApiKey = '';

  DisplayMode get displayMode => _displayMode;
  double get gridSize => _gridSize;
  bool get hideNonReleased => _hideNonReleased;
  bool get notificationCenterDebug => _notificationCenterDebug;
  bool get advancedTracking => _advancedTracking;
  PreviousEpisodesBehavior get previousEpisodes => _previousEpisodes;
  String? get watchProvidersCountry => _watchProvidersCountry;
  bool get isSwipeModeEnabled => _swipeModeEnabled;
  String get swipeTargetList => _swipeTargetList;

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
      // v1.3.0 'swipe' mode falls back to grid in v1.4.0 (#312).
      if (_displayMode == DisplayMode.swipe) {
        _displayMode = DisplayMode.grid;
      }
    }

    final double? storedGridSize = _prefs.getDouble('gridSize');
    if (storedGridSize != null) {
      _gridSize = storedGridSize.clamp(2.0, 4.0);
    }
    _hideNonReleased = _prefs.getBool('hideNonReleased') ?? false;
    _notificationCenterDebug =
        _prefs.getBool('notificationCenterDebug') ?? false;
    _advancedTracking = _prefs.getBool(advancedTrackingKey) ?? false;
    _watchProvidersCountry = _prefs.getString(watchProvidersCountryKey);
    final storedPrevious = _prefs.getString(previousEpisodesKey);
    if (storedPrevious != null) {
      _previousEpisodes = PreviousEpisodesBehavior.values.firstWhere(
        (b) => b.name == storedPrevious,
        orElse: () => PreviousEpisodesBehavior.ask,
      );
    }
    _swipeModeEnabled = _prefs.getBool(swipeModeEnabledKey) ?? true;
    _swipeTargetList = _prefs.getString('swipeTargetList') ?? 'watchlist';

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
    final effective = mode == DisplayMode.swipe ? DisplayMode.grid : mode;
    _displayMode = effective;
    await _prefs.setInt('displayMode', effective.index);
    notifyListeners();
  }

  Future<void> setGridSize(double size) async {
    final clamped = size.clamp(2.0, 4.0);
    _gridSize = clamped;
    await _prefs.setDouble('gridSize', clamped);
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

  Future<void> setAdvancedTracking(bool enabled) async {
    _advancedTracking = enabled;
    await _prefs.setBool(advancedTrackingKey, enabled);
    notifyListeners();
  }

  Future<void> setSwipeModeEnabled(bool enabled) async {
    _swipeModeEnabled = enabled;
    await _prefs.setBool(swipeModeEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setSwipeTargetList(String listName) async {
    _swipeTargetList = listName;
    await _prefs.setString('swipeTargetList', listName);
    notifyListeners();
  }

  Future<void> setPreviousEpisodes(PreviousEpisodesBehavior value) async {
    _previousEpisodes = value;
    await _prefs.setString(previousEpisodesKey, value.name);
    notifyListeners();
  }

  Future<void> setWatchProvidersCountry(String? countryCode) async {
    final normalized = countryCode?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      _watchProvidersCountry = null;
      await _prefs.remove(watchProvidersCountryKey);
    } else {
      _watchProvidersCountry = normalized;
      await _prefs.setString(watchProvidersCountryKey, normalized);
    }
    notifyListeners();
  }

  /// Effective country code for watch providers: the user override if set,
  /// otherwise the device's country code, falling back to 'FR'.
  String resolveWatchProvidersCountry([Locale? deviceLocale]) {
    if (_watchProvidersCountry != null && _watchProvidersCountry!.isNotEmpty) {
      return _watchProvidersCountry!;
    }
    if (deviceLocale != null &&
        deviceLocale.countryCode != null &&
        deviceLocale.countryCode!.isNotEmpty) {
      return deviceLocale.countryCode!.toUpperCase();
    }
    for (final locale in PlatformDispatcher.instance.locales) {
      final code = locale.countryCode;
      if (code != null && code.isNotEmpty) {
        return code.toUpperCase();
      }
    }
    final defaultCode = PlatformDispatcher.instance.locale.countryCode;
    if (defaultCode != null && defaultCode.isNotEmpty) {
      return defaultCode.toUpperCase();
    }
    return 'FR';
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
