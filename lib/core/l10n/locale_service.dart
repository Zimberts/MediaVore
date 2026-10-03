import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:mediavore/core/l10n/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Source of truth for the active app language.
///
/// Holds the user's override (or `null` to follow the device) and resolves
/// the effective [AppLanguage] used for the UI and TMDB requests. Notifies
/// listeners whenever the effective language changes.
@lazySingleton
class LocaleService extends ChangeNotifier {
  static const String overrideKey = 'appLanguage';
  static const String cacheLanguageKey = 'cacheTmdbLanguage';

  final SharedPreferences _prefs;
  final List<Locale> Function() _deviceLocales;

  LocaleService(SharedPreferences prefs)
    : this.withDeviceLocales(prefs, () => PlatformDispatcher.instance.locales);

  @visibleForTesting
  LocaleService.withDeviceLocales(this._prefs, this._deviceLocales) {
    _current = _resolve();
  }

  late AppLanguage _current;

  /// Language picked by the user, or `null` when following the device.
  AppLanguage? get override =>
      appLanguageForCode(_prefs.getString(overrideKey));

  /// Effective language: [override], else the device's, else English.
  AppLanguage get current => _current;

  /// Value for TMDB's `language` request parameter.
  String get tmdbLanguage => _current.tmdbTag;

  AppLanguage _resolve() => override ?? resolveAppLanguage(_deviceLocales());

  /// Sets the language override; `null` follows the device locale again.
  Future<void> setOverride(AppLanguage? language) async {
    if (language == null) {
      await _prefs.remove(overrideKey);
    } else {
      await _prefs.setString(overrideKey, language.code);
    }
    _refresh();
  }

  /// Call when the device locales change (only matters without override).
  void handleDeviceLocalesChanged() => _refresh();

  void _refresh() {
    final next = _resolve();
    if (next.code == _current.code) return;
    _current = next;
    notifyListeners();
  }

  /// Whether the TMDB cache was filled in another language than [current].
  bool get isCacheLanguageStale =>
      _prefs.getString(cacheLanguageKey) != tmdbLanguage;

  /// Records that the TMDB cache now holds [current]-language data.
  Future<void> markCacheLanguage() =>
      _prefs.setString(cacheLanguageKey, tmdbLanguage);
}
