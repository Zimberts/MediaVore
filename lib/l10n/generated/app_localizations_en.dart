// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MediaVore';

  @override
  String get appLoading => 'Loading MediaVore...';

  @override
  String appStartupFailed(String error) {
    return 'Failed to start app:\n$error';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonImport => 'Import';

  @override
  String get commonOpenSettings => 'Open Settings';

  @override
  String get navSearch => 'Search';

  @override
  String get navMyLists => 'My Lists';

  @override
  String get navSeen => 'Seen';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get importListTitle => 'Import List';

  @override
  String importListMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You are about to import a list with $count items.',
      one: 'You are about to import a list with 1 item.',
    );
    return '$_temp0';
  }

  @override
  String get importListNameLabel => 'List Name';

  @override
  String get importListNameHint => 'Enter name';

  @override
  String get tmdbCredentialRequiredTitle => 'TMDB Credential Required';

  @override
  String get tmdbCredentialRequiredMessage =>
      'To use this app, you need a TMDB credential (v3 API key or v4 read token). You can get one at themoviedb.org.';

  @override
  String get tmdbCredentialHint => 'Enter TMDB v3 API key or v4 read token';

  @override
  String get tmdbCredentialLater =>
      'You can set your API key later in Settings (accessible from the My Lists, Seen, or Alerts tabs).';

  @override
  String get tmdbCredentialCancelForNow => 'Cancel for now';

  @override
  String get achievementUnlocked => 'Achievement Unlocked!';

  @override
  String get searchErrorMissingApiKey =>
      'Add your TMDB API key in Settings to search and discover media.';

  @override
  String get searchErrorInvalidApiKey =>
      'Your TMDB API key was rejected. Check it in Settings.';

  @override
  String get searchErrorOffline =>
      'You\'re offline. Check your connection and try again.';

  @override
  String get searchErrorServer =>
      'TMDB is unavailable right now. Please try again later.';

  @override
  String get searchErrorUnknown =>
      'Something went wrong while loading results.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsThemeMode => 'Theme Mode';

  @override
  String get settingsThemeModeSystem => 'System';

  @override
  String get settingsThemeModeLight => 'Light';

  @override
  String get settingsThemeModeDark => 'Dark';

  @override
  String get settingsLightTheme => 'Light Theme';

  @override
  String get settingsDarkTheme => 'Dark Theme';

  @override
  String get settingsSectionMilestones => 'Gaming & Milestones';

  @override
  String get settingsAchievements => 'Achievements';

  @override
  String get settingsAchievementsSubtitle =>
      'View your collection of badges and progress.';

  @override
  String get settingsSectionListsDisplay => 'Lists Display';

  @override
  String get settingsHideNonReleased => 'Hide Non-Released Media';

  @override
  String get settingsHideNonReleasedSubtitle =>
      'Only show movies and episodes that have already aired.';

  @override
  String get settingsSectionStorage => 'Storage & History';

  @override
  String get settingsStorage => 'Storage & Data';

  @override
  String get settingsStorageSubtitle =>
      'Manage cache, exports, and viewing history database.';

  @override
  String get settingsSectionApi => 'API Configuration';

  @override
  String get settingsTmdbCredential => 'TMDB API Credential';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsAboutDescription =>
      'A simple media tracking app using TMDB.';
}
