import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MediaVore'**
  String get appTitle;

  /// No description provided for @appLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading MediaVore...'**
  String get appLoading;

  /// No description provided for @appStartupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start app:\n{error}'**
  String appStartupFailed(String error);

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get commonImport;

  /// No description provided for @commonOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get commonOpenSettings;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navMyLists.
  ///
  /// In en, this message translates to:
  /// **'My Lists'**
  String get navMyLists;

  /// No description provided for @navSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get navSeen;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @importListTitle.
  ///
  /// In en, this message translates to:
  /// **'Import List'**
  String get importListTitle;

  /// No description provided for @importListMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You are about to import a list with 1 item.} other{You are about to import a list with {count} items.}}'**
  String importListMessage(int count);

  /// No description provided for @importListNameLabel.
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get importListNameLabel;

  /// No description provided for @importListNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get importListNameHint;

  /// No description provided for @tmdbCredentialRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'TMDB Credential Required'**
  String get tmdbCredentialRequiredTitle;

  /// No description provided for @tmdbCredentialRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'To use this app, you need a TMDB credential (v3 API key or v4 read token). You can get one at themoviedb.org.'**
  String get tmdbCredentialRequiredMessage;

  /// No description provided for @tmdbCredentialHint.
  ///
  /// In en, this message translates to:
  /// **'Enter TMDB v3 API key or v4 read token'**
  String get tmdbCredentialHint;

  /// No description provided for @tmdbCredentialLater.
  ///
  /// In en, this message translates to:
  /// **'You can set your API key later in Settings (accessible from the My Lists, Seen, or Alerts tabs).'**
  String get tmdbCredentialLater;

  /// No description provided for @tmdbCredentialCancelForNow.
  ///
  /// In en, this message translates to:
  /// **'Cancel for now'**
  String get tmdbCredentialCancelForNow;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get achievementUnlocked;

  /// No description provided for @searchErrorMissingApiKey.
  ///
  /// In en, this message translates to:
  /// **'Add your TMDB API key in Settings to search and discover media.'**
  String get searchErrorMissingApiKey;

  /// No description provided for @searchErrorInvalidApiKey.
  ///
  /// In en, this message translates to:
  /// **'Your TMDB API key was rejected. Check it in Settings.'**
  String get searchErrorInvalidApiKey;

  /// No description provided for @searchErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection and try again.'**
  String get searchErrorOffline;

  /// No description provided for @searchErrorServer.
  ///
  /// In en, this message translates to:
  /// **'TMDB is unavailable right now. Please try again later.'**
  String get searchErrorServer;

  /// No description provided for @searchErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading results.'**
  String get searchErrorUnknown;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeMode;

  /// No description provided for @settingsThemeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeModeSystem;

  /// No description provided for @settingsThemeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeModeLight;

  /// No description provided for @settingsThemeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeModeDark;

  /// No description provided for @settingsLightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get settingsLightTheme;

  /// No description provided for @settingsDarkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get settingsDarkTheme;

  /// No description provided for @settingsSectionMilestones.
  ///
  /// In en, this message translates to:
  /// **'Gaming & Milestones'**
  String get settingsSectionMilestones;

  /// No description provided for @settingsAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get settingsAchievements;

  /// No description provided for @settingsAchievementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your collection of badges and progress.'**
  String get settingsAchievementsSubtitle;

  /// No description provided for @settingsSectionListsDisplay.
  ///
  /// In en, this message translates to:
  /// **'Lists Display'**
  String get settingsSectionListsDisplay;

  /// No description provided for @settingsHideNonReleased.
  ///
  /// In en, this message translates to:
  /// **'Hide Non-Released Media'**
  String get settingsHideNonReleased;

  /// No description provided for @settingsHideNonReleasedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only show movies and episodes that have already aired.'**
  String get settingsHideNonReleasedSubtitle;

  /// No description provided for @settingsSectionStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage & History'**
  String get settingsSectionStorage;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage & Data'**
  String get settingsStorage;

  /// No description provided for @settingsStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage cache, exports, and viewing history database.'**
  String get settingsStorageSubtitle;

  /// No description provided for @settingsSectionApi.
  ///
  /// In en, this message translates to:
  /// **'API Configuration'**
  String get settingsSectionApi;

  /// No description provided for @settingsTmdbCredential.
  ///
  /// In en, this message translates to:
  /// **'TMDB API Credential'**
  String get settingsTmdbCredential;

  /// No description provided for @settingsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsNotSet;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsAboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A simple media tracking app using TMDB.'**
  String get settingsAboutDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
