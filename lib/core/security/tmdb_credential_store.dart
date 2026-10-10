import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the TMDB credential (v3 API key or v4 read token) in the platform
/// secure storage (Keychain on iOS, Keystore-backed on Android).
///
/// The value is cached in memory after [load] so callers can read it
/// synchronously.
class TmdbCredentialStore {
  /// Key used in the secure storage.
  static const secureStorageKey = 'tmdbApiKey';

  /// Key under which older versions stored the credential in plain
  /// SharedPreferences. Migrated then removed by [load].
  static const legacyPrefsKey = 'tmdbApiKey';

  final FlutterSecureStorage _secureStorage;
  String _credential;

  TmdbCredentialStore._(this._secureStorage, this._credential);

  /// Reads the credential from secure storage, migrating a legacy plain-text
  /// value from [prefs] on first launch.
  ///
  /// The legacy value is only removed once it is safely in secure storage
  /// (or secure storage already holds a credential), so a failing keystore
  /// never loses the user's key.
  static Future<TmdbCredentialStore> load({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  }) async {
    var credential = '';
    var secureReadable = true;
    try {
      credential = await secureStorage.read(key: secureStorageKey) ?? '';
    } catch (e) {
      secureReadable = false;
      debugPrint('[TmdbCredentialStore] secure read failed: $e');
    }

    final legacy = prefs.getString(legacyPrefsKey);
    if (legacy == null) {
      return TmdbCredentialStore._(secureStorage, credential);
    }

    if (credential.isEmpty && legacy.trim().isNotEmpty) {
      if (!secureReadable) {
        // Keep the legacy value in place; retry the migration next launch.
        return TmdbCredentialStore._(secureStorage, legacy.trim());
      }
      try {
        await secureStorage.write(key: secureStorageKey, value: legacy.trim());
        credential = legacy.trim();
      } catch (e) {
        debugPrint('[TmdbCredentialStore] migration failed: $e');
        return TmdbCredentialStore._(secureStorage, legacy.trim());
      }
    }

    await prefs.remove(legacyPrefsKey);
    return TmdbCredentialStore._(secureStorage, credential);
  }

  /// The stored credential, or an empty string when none is set.
  String get credential => _credential;

  /// Persists [value] (trimmed) in secure storage; an empty value deletes it.
  Future<void> save(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _secureStorage.delete(key: secureStorageKey);
    } else {
      await _secureStorage.write(key: secureStorageKey, value: trimmed);
    }
    _credential = trimmed;
  }
}
