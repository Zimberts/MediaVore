import 'dart:ui';

/// A language the app UI and TMDB requests can be shown in.
///
/// To add a language: add an `lib/l10n/app_<code>.arb` file and one entry to
/// [supportedAppLanguages]. Nothing else has to change.
class AppLanguage {
  /// ISO 639-1 code, matching the ARB file suffix (e.g. `fr`).
  final String code;

  /// Value sent as TMDB's `language` parameter (e.g. `fr-FR`).
  final String tmdbTag;

  /// Name of the language written in that language (e.g. `Français`).
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.tmdbTag,
    required this.nativeName,
  });

  Locale get locale => Locale(code);

  @override
  String toString() => 'AppLanguage($code)';
}

const AppLanguage englishLanguage = AppLanguage(
  code: 'en',
  tmdbTag: 'en-US',
  nativeName: 'English',
);

/// Every language the app ships. The first entry is the fallback.
const List<AppLanguage> supportedAppLanguages = [
  englishLanguage,
  AppLanguage(code: 'fr', tmdbTag: 'fr-FR', nativeName: 'Français'),
];

/// Used when none of the device locales is supported.
const AppLanguage fallbackAppLanguage = englishLanguage;

/// Returns the supported language whose code is [code], or `null`.
AppLanguage? appLanguageForCode(String? code) {
  if (code == null) return null;
  for (final language in supportedAppLanguages) {
    if (language.code == code) return language;
  }
  return null;
}

/// Picks the first supported language among [preferred] (device locales in
/// priority order), falling back to [fallbackAppLanguage].
AppLanguage resolveAppLanguage(Iterable<Locale> preferred) {
  for (final locale in preferred) {
    final match = appLanguageForCode(locale.languageCode);
    if (match != null) return match;
  }
  return fallbackAppLanguage;
}
