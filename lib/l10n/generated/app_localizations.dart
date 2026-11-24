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

  /// No description provided for @appStartupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'MediaVore could not start'**
  String get appStartupFailedTitle;

  /// No description provided for @appStartupFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while loading your data. Please try again.'**
  String get appStartupFailedMessage;

  /// No description provided for @appStartupTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get appStartupTechnicalDetails;

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

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @emptyStateSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search a movie or series'**
  String get emptyStateSearchAction;

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

  /// No description provided for @tmdbOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to TMDB'**
  String get tmdbOnboardingTitle;

  /// No description provided for @tmdbOnboardingWhy.
  ///
  /// In en, this message translates to:
  /// **'MediaVore gets movie and series data (posters, synopses, release dates) from The Movie Database (TMDB). TMDB asks each user for a free personal key.'**
  String get tmdbOnboardingWhy;

  /// No description provided for @tmdbOnboardingStepGetKey.
  ///
  /// In en, this message translates to:
  /// **'1. Create a free TMDB account, then open its API settings page.'**
  String get tmdbOnboardingStepGetKey;

  /// No description provided for @tmdbOnboardingOpenTmdb.
  ///
  /// In en, this message translates to:
  /// **'Open the TMDB API page'**
  String get tmdbOnboardingOpenTmdb;

  /// No description provided for @tmdbOnboardingStepPaste.
  ///
  /// In en, this message translates to:
  /// **'2. Copy the \"API Read Access Token\" (or the \"API Key\") and paste it below.'**
  String get tmdbOnboardingStepPaste;

  /// No description provided for @tmdbCredentialLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the browser. Link copied: {url}'**
  String tmdbCredentialLinkCopied(String url);

  /// No description provided for @tmdbCredentialHint.
  ///
  /// In en, this message translates to:
  /// **'Enter TMDB v3 API key or v4 read token'**
  String get tmdbCredentialHint;

  /// No description provided for @tmdbCredentialPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get tmdbCredentialPaste;

  /// No description provided for @tmdbCredentialShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get tmdbCredentialShow;

  /// No description provided for @tmdbCredentialHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get tmdbCredentialHide;

  /// No description provided for @tmdbCredentialVerifyAndSave.
  ///
  /// In en, this message translates to:
  /// **'Verify and save'**
  String get tmdbCredentialVerifyAndSave;

  /// No description provided for @tmdbCredentialVerifying.
  ///
  /// In en, this message translates to:
  /// **'Checking with TMDB…'**
  String get tmdbCredentialVerifying;

  /// No description provided for @tmdbCredentialSaved.
  ///
  /// In en, this message translates to:
  /// **'TMDB key verified and saved.'**
  String get tmdbCredentialSaved;

  /// No description provided for @tmdbCredentialInvalid.
  ///
  /// In en, this message translates to:
  /// **'TMDB rejected this key. Check that you copied the whole API key or read access token.'**
  String get tmdbCredentialInvalid;

  /// No description provided for @tmdbCredentialCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'The key could not be verified: {reason}'**
  String tmdbCredentialCheckFailed(String reason);

  /// No description provided for @tmdbCredentialSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save without verifying'**
  String get tmdbCredentialSaveAnyway;

  /// No description provided for @tmdbCredentialRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove key'**
  String get tmdbCredentialRemove;

  /// No description provided for @tmdbCredentialLater.
  ///
  /// In en, this message translates to:
  /// **'You can set your API key later in Me › TMDB API Credential.'**
  String get tmdbCredentialLater;

  /// No description provided for @tmdbCredentialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get tmdbCredentialSkip;

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

  /// No description provided for @paletteNamePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get paletteNamePaper;

  /// No description provided for @paletteNameSand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get paletteNameSand;

  /// No description provided for @paletteNameMist.
  ///
  /// In en, this message translates to:
  /// **'Mist'**
  String get paletteNameMist;

  /// No description provided for @paletteNameInk.
  ///
  /// In en, this message translates to:
  /// **'Ink'**
  String get paletteNameInk;

  /// No description provided for @paletteNameNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get paletteNameNight;

  /// No description provided for @paletteNameOled.
  ///
  /// In en, this message translates to:
  /// **'OLED black'**
  String get paletteNameOled;

  /// No description provided for @paletteNameClassicLight.
  ///
  /// In en, this message translates to:
  /// **'Classic Light'**
  String get paletteNameClassicLight;

  /// No description provided for @paletteNameParchment.
  ///
  /// In en, this message translates to:
  /// **'Parchment'**
  String get paletteNameParchment;

  /// No description provided for @paletteNameMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get paletteNameMint;

  /// No description provided for @paletteNameSolarizedLight.
  ///
  /// In en, this message translates to:
  /// **'Solarized Light'**
  String get paletteNameSolarizedLight;

  /// No description provided for @paletteNamePinky.
  ///
  /// In en, this message translates to:
  /// **'Pinky'**
  String get paletteNamePinky;

  /// No description provided for @paletteNameClassicDark.
  ///
  /// In en, this message translates to:
  /// **'Classic Dark'**
  String get paletteNameClassicDark;

  /// No description provided for @paletteNameSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get paletteNameSlate;

  /// No description provided for @paletteNameMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get paletteNameMidnight;

  /// No description provided for @paletteNameEspresso.
  ///
  /// In en, this message translates to:
  /// **'Espresso'**
  String get paletteNameEspresso;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get profileTitle;

  /// No description provided for @profileAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profileAchievements;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance, display and preferences.'**
  String get profileSettingsSubtitle;

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

  /// No description provided for @dataSectionCache.
  ///
  /// In en, this message translates to:
  /// **'Cache Management'**
  String get dataSectionCache;

  /// No description provided for @dataCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache Size'**
  String get dataCacheSize;

  /// No description provided for @dataCleanupCache.
  ///
  /// In en, this message translates to:
  /// **'Cleanup Cache'**
  String get dataCleanupCache;

  /// No description provided for @dataCleanupCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove old, unused search results and details.'**
  String get dataCleanupCacheSubtitle;

  /// No description provided for @dataCleanupCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove search results and details older than 60 days that are not in your lists.'**
  String get dataCleanupCacheMessage;

  /// No description provided for @dataFillCache.
  ///
  /// In en, this message translates to:
  /// **'Fill Cache'**
  String get dataFillCache;

  /// No description provided for @dataFillCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-cache all items in your lists and recent history for offline use.'**
  String get dataFillCacheSubtitle;

  /// No description provided for @dataCachingTitles.
  ///
  /// In en, this message translates to:
  /// **'Caching titles: {done} / {total}'**
  String dataCachingTitles(int done, int total);

  /// No description provided for @dataWipeCache.
  ///
  /// In en, this message translates to:
  /// **'Wipe All Cache'**
  String get dataWipeCache;

  /// No description provided for @dataWipeCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete everything from cache.'**
  String get dataWipeCacheSubtitle;

  /// No description provided for @dataWipeCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete ALL cached posters and details. You will need internet to see them again.'**
  String get dataWipeCacheMessage;

  /// No description provided for @dataSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataSectionData;

  /// No description provided for @dataSeenDbSize.
  ///
  /// In en, this message translates to:
  /// **'Seen Database Size'**
  String get dataSeenDbSize;

  /// No description provided for @dataRefetchRuntimes.
  ///
  /// In en, this message translates to:
  /// **'Refetch missing data'**
  String get dataRefetchRuntimes;

  /// No description provided for @dataRefetchRuntimesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch missing runtimes and genres for your history.'**
  String get dataRefetchRuntimesSubtitle;

  /// No description provided for @dataRefetchTitle.
  ///
  /// In en, this message translates to:
  /// **'Refetch Data'**
  String get dataRefetchTitle;

  /// No description provided for @dataRefetchMessage.
  ///
  /// In en, this message translates to:
  /// **'This will check your seen history and fetch any missing runtimes or genres from TMDb. This might take a while.'**
  String get dataRefetchMessage;

  /// No description provided for @dataExportAll.
  ///
  /// In en, this message translates to:
  /// **'Export All Data'**
  String get dataExportAll;

  /// No description provided for @dataExportAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export seen, likes, notifications and lists as a single MDV file.'**
  String get dataExportAllSubtitle;

  /// No description provided for @dataSaveToDevice.
  ///
  /// In en, this message translates to:
  /// **'Save to device'**
  String get dataSaveToDevice;

  /// No description provided for @dataShareViaSystem.
  ///
  /// In en, this message translates to:
  /// **'Share via System'**
  String get dataShareViaSystem;

  /// No description provided for @dataExportShareText.
  ///
  /// In en, this message translates to:
  /// **'MediaVore Export'**
  String get dataExportShareText;

  /// No description provided for @dataImportAll.
  ///
  /// In en, this message translates to:
  /// **'Import All Data'**
  String get dataImportAll;

  /// No description provided for @dataImportAllSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import seen, likes, notifications and lists from an export MDV or ZIP.'**
  String get dataImportAllSubtitle;

  /// No description provided for @dataPopulateQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'Populate Quick Add from Seen History'**
  String get dataPopulateQuickAdd;

  /// No description provided for @dataPopulateQuickAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compute next episodes from your seen history and save them to Quick Add.'**
  String get dataPopulateQuickAddSubtitle;

  /// No description provided for @dataPopulateQuickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Populate Quick Add'**
  String get dataPopulateQuickAddTitle;

  /// No description provided for @dataPopulateQuickAddMessage.
  ///
  /// In en, this message translates to:
  /// **'This will compute next unseen episodes for your TV shows and add them to Quick Add. Proceed?'**
  String get dataPopulateQuickAddMessage;

  /// No description provided for @dataPopulateQuickAddDone.
  ///
  /// In en, this message translates to:
  /// **'Quick Add populated from history.'**
  String get dataPopulateQuickAddDone;

  /// No description provided for @dataSectionAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievement Data'**
  String get dataSectionAchievements;

  /// No description provided for @dataClearAchievements.
  ///
  /// In en, this message translates to:
  /// **'Clear Achievement Database'**
  String get dataClearAchievements;

  /// No description provided for @dataClearAchievementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all persisted achievement milestones.'**
  String get dataClearAchievementsSubtitle;

  /// No description provided for @dataClearAchievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Achievements?'**
  String get dataClearAchievementsTitle;

  /// No description provided for @dataClearAchievementsMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove all persisted achievement dates from the database. Achievements calculated from your watch history will reappear automatically.'**
  String get dataClearAchievementsMessage;

  /// No description provided for @dataClearAchievementsDone.
  ///
  /// In en, this message translates to:
  /// **'Achievement database cleared.'**
  String get dataClearAchievementsDone;

  /// No description provided for @dataSectionDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get dataSectionDebug;

  /// No description provided for @dataNotificationDebug.
  ///
  /// In en, this message translates to:
  /// **'Notification Center Debug'**
  String get dataNotificationDebug;

  /// No description provided for @dataNotificationDebugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show hidden Notification Center items and why they were omitted.'**
  String get dataNotificationDebugSubtitle;

  /// No description provided for @commonProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get commonProcessing;

  /// No description provided for @dataExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting data...'**
  String get dataExporting;

  /// No description provided for @dataReadingBackup.
  ///
  /// In en, this message translates to:
  /// **'Reading backup...'**
  String get dataReadingBackup;

  /// No description provided for @dataSaveExportDialog.
  ///
  /// In en, this message translates to:
  /// **'Save Export'**
  String get dataSaveExportDialog;

  /// No description provided for @dataFileSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved successfully'**
  String get dataFileSaved;

  /// No description provided for @dataSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}. Try using \"Share\" instead.'**
  String dataSaveFailed(String error);

  /// No description provided for @dataInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a valid .mdv or .zip export file.'**
  String get dataInvalidFile;

  /// No description provided for @dataImportPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Preview'**
  String get dataImportPreviewTitle;

  /// No description provided for @dataImportPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'This file contains:\nSeen: {seen}\nLikes: {likes}\nNotifications: {notifications}\nLists: {lists}\n{warnings}\nChoose how to apply the data to your current profile.'**
  String dataImportPreviewMessage(
    int seen,
    int likes,
    int notifications,
    int lists,
    String warnings,
  );

  /// No description provided for @dataImportSkippedRows.
  ///
  /// In en, this message translates to:
  /// **'{count} invalid row(s) will be skipped:'**
  String dataImportSkippedRows(int count);

  /// No description provided for @dataImportedAppended.
  ///
  /// In en, this message translates to:
  /// **'Imported (Appended)'**
  String get dataImportedAppended;

  /// No description provided for @dataAppend.
  ///
  /// In en, this message translates to:
  /// **'Append'**
  String get dataAppend;

  /// No description provided for @dataImportedMerged.
  ///
  /// In en, this message translates to:
  /// **'Imported (Merged)'**
  String get dataImportedMerged;

  /// No description provided for @dataMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get dataMerge;

  /// No description provided for @dataImportedReplaced.
  ///
  /// In en, this message translates to:
  /// **'Imported (Replaced)'**
  String get dataImportedReplaced;

  /// No description provided for @dataReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get dataReplace;

  /// No description provided for @dataImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: Invalid file format'**
  String get dataImportFailed;

  /// No description provided for @dataImportFailedReason.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {reason}'**
  String dataImportFailedReason(String reason);

  /// No description provided for @dataReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'DANGER: Replace History'**
  String get dataReplaceTitle;

  /// No description provided for @dataReplaceMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete all your current seen history and replace it with the data from the file. This action cannot be undone. Are you absolutely sure?'**
  String get dataReplaceMessage;

  /// No description provided for @dataReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, Replace Everything'**
  String get dataReplaceConfirm;

  /// No description provided for @commonProceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get commonProceed;

  /// No description provided for @listsDisplayOptions.
  ///
  /// In en, this message translates to:
  /// **'Display Options'**
  String get listsDisplayOptions;

  /// No description provided for @listsSharingImporting.
  ///
  /// In en, this message translates to:
  /// **'Sharing & Importing'**
  String get listsSharingImporting;

  /// No description provided for @listsScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get listsScanQr;

  /// No description provided for @listsImportViaLink.
  ///
  /// In en, this message translates to:
  /// **'Import via Link'**
  String get listsImportViaLink;

  /// No description provided for @listsShareWebLink.
  ///
  /// In en, this message translates to:
  /// **'Share Web Link (WhatsApp/SMS)'**
  String get listsShareWebLink;

  /// No description provided for @listsShareLinkMessage.
  ///
  /// In en, this message translates to:
  /// **'Check out my {list} on MediaVore: {link}'**
  String listsShareLinkMessage(String list, String link);

  /// No description provided for @listsQrShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code to import my {list} on MediaVore'**
  String listsQrShareMessage(String list);

  /// No description provided for @listsQrShareError.
  ///
  /// In en, this message translates to:
  /// **'Error sharing QR code: {error}'**
  String listsQrShareError(String error);

  /// No description provided for @listsShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share {list}'**
  String listsShareTitle(String list);

  /// No description provided for @listsQrCaption.
  ///
  /// In en, this message translates to:
  /// **'MediaVore List Share'**
  String get listsQrCaption;

  /// No description provided for @listsQrHint.
  ///
  /// In en, this message translates to:
  /// **'Scan this with another phone to import the list.'**
  String get listsQrHint;

  /// No description provided for @listsShareQrImage.
  ///
  /// In en, this message translates to:
  /// **'Share QR Code Image'**
  String get listsShareQrImage;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @listsScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan MediaVore List'**
  String get listsScanTitle;

  /// No description provided for @listsScanHint.
  ///
  /// In en, this message translates to:
  /// **'Point your camera at a MediaVore QR code'**
  String get listsScanHint;

  /// No description provided for @listsPasteLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the shared link here'**
  String get listsPasteLinkHint;

  /// No description provided for @listsShareLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get listsShareLinkLabel;

  /// No description provided for @listsInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid link format'**
  String get listsInvalidLink;

  /// No description provided for @listsConfirmImport.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get listsConfirmImport;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @listsSortOptions.
  ///
  /// In en, this message translates to:
  /// **'Sort Options'**
  String get listsSortOptions;

  /// No description provided for @listsMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get listsMoreActions;

  /// No description provided for @listsSortManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Order'**
  String get listsSortManual;

  /// No description provided for @listsSortManualHint.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop items to reorder'**
  String get listsSortManualHint;

  /// No description provided for @listsSortReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get listsSortReleaseDate;

  /// No description provided for @listsSortReleaseDateHint.
  ///
  /// In en, this message translates to:
  /// **'Sort by when it was released'**
  String get listsSortReleaseDateHint;

  /// No description provided for @listsSortShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get listsSortShuffle;

  /// No description provided for @listsSortShuffleHint.
  ///
  /// In en, this message translates to:
  /// **'Randomize the list'**
  String get listsSortShuffleHint;

  /// No description provided for @listsReverseOrder.
  ///
  /// In en, this message translates to:
  /// **'Reverse Order'**
  String get listsReverseOrder;

  /// No description provided for @listsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String listsSelectedCount(int count);

  /// No description provided for @listsWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get listsWatchlist;

  /// No description provided for @listsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items in this list.'**
  String get listsEmpty;

  /// No description provided for @listsCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create New List'**
  String get listsCreateNew;

  /// No description provided for @listsNewList.
  ///
  /// In en, this message translates to:
  /// **'New List'**
  String get listsNewList;

  /// No description provided for @listsNameHint.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get listsNameHint;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @listsDeleteList.
  ///
  /// In en, this message translates to:
  /// **'Delete List'**
  String get listsDeleteList;

  /// No description provided for @listsDeleteListMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{list}\"? This will also remove all items from this list.'**
  String listsDeleteListMessage(String list);

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @mediaSeasonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 season} other{{count} seasons}}'**
  String mediaSeasonCount(int count);

  /// No description provided for @mediaRuntimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String mediaRuntimeMinutes(int minutes);

  /// No description provided for @seenRemoveLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove log?'**
  String get seenRemoveLogTitle;

  /// No description provided for @seenRemoveLogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this viewing entry from your history?'**
  String get seenRemoveLogMessage;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @seenSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get seenSortBy;

  /// No description provided for @seenMediaType.
  ///
  /// In en, this message translates to:
  /// **'Media Type'**
  String get seenMediaType;

  /// No description provided for @commonMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get commonMovies;

  /// No description provided for @commonTvShows.
  ///
  /// In en, this message translates to:
  /// **'TV Shows'**
  String get commonTvShows;

  /// No description provided for @seenTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get seenTitle;

  /// No description provided for @seenSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search history...'**
  String get seenSearchHint;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @seenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items seen yet.'**
  String get seenEmpty;

  /// No description provided for @seenEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Mark a movie or an episode as seen to start your history.'**
  String get seenEmptyHint;

  /// No description provided for @seenNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found.'**
  String get seenNoMatches;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Media Stats'**
  String get statsTitle;

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data yet. Start watching!'**
  String get statsEmpty;

  /// No description provided for @statsToggleMetric.
  ///
  /// In en, this message translates to:
  /// **'Toggle Metric (Logs/Time)'**
  String get statsToggleMetric;

  /// No description provided for @statsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get statsAllTime;

  /// No description provided for @statsYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get statsYear;

  /// No description provided for @statsMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statsMonth;

  /// No description provided for @statsSelectYear.
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get statsSelectYear;

  /// No description provided for @statsSelectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get statsSelectPeriod;

  /// No description provided for @statsPreviousPeriod.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get statsPreviousPeriod;

  /// No description provided for @statsNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get statsNextPeriod;

  /// No description provided for @statsTotalWatchTime.
  ///
  /// In en, this message translates to:
  /// **'Total Watch Time'**
  String get statsTotalWatchTime;

  /// No description provided for @statsDuration.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h {minutes}m'**
  String statsDuration(int days, int hours, int minutes);

  /// No description provided for @statsHallOfFame.
  ///
  /// In en, this message translates to:
  /// **'Hall of Fame ({metric})'**
  String statsHallOfFame(String metric);

  /// No description provided for @statsMostWatchedMovie.
  ///
  /// In en, this message translates to:
  /// **'Most Watched Movie'**
  String get statsMostWatchedMovie;

  /// No description provided for @statsMostWatchedSeries.
  ///
  /// In en, this message translates to:
  /// **'Most Watched Series'**
  String get statsMostWatchedSeries;

  /// No description provided for @statsMostWatchedEpisode.
  ///
  /// In en, this message translates to:
  /// **'Most Watched Episode'**
  String get statsMostWatchedEpisode;

  /// No description provided for @statsActivityLogs.
  ///
  /// In en, this message translates to:
  /// **'Viewing Activity (logs)'**
  String get statsActivityLogs;

  /// No description provided for @statsActivityMinutes.
  ///
  /// In en, this message translates to:
  /// **'Viewing Activity (minutes)'**
  String get statsActivityMinutes;

  /// No description provided for @statsLogCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 log} other{{count} logs}}'**
  String statsLogCount(int count);

  /// No description provided for @statsHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String statsHours(String hours);

  /// No description provided for @statsNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity data'**
  String get statsNoActivity;

  /// No description provided for @statsTooltip.
  ///
  /// In en, this message translates to:
  /// **'{label}\n{value} {unit}'**
  String statsTooltip(String label, int value, String unit);

  /// No description provided for @statsMediaSplit.
  ///
  /// In en, this message translates to:
  /// **'Media Split ({metric})'**
  String statsMediaSplit(String metric);

  /// No description provided for @statsTopGenres.
  ///
  /// In en, this message translates to:
  /// **'Top Genres (by {metric})'**
  String statsTopGenres(String metric);

  /// No description provided for @statsGenreValue.
  ///
  /// In en, this message translates to:
  /// **'{value} ({percent}%)'**
  String statsGenreValue(String value, String percent);

  /// No description provided for @statsMetricLogs.
  ///
  /// In en, this message translates to:
  /// **'logs'**
  String get statsMetricLogs;

  /// No description provided for @statsMetricTime.
  ///
  /// In en, this message translates to:
  /// **'time'**
  String get statsMetricTime;

  /// No description provided for @statsNoDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No viewing data for this period'**
  String get statsNoDataForPeriod;

  /// No description provided for @statsDecades.
  ///
  /// In en, this message translates to:
  /// **'By release decade'**
  String get statsDecades;

  /// No description provided for @statsDecadeBefore1990.
  ///
  /// In en, this message translates to:
  /// **'Before 1990'**
  String get statsDecadeBefore1990;

  /// No description provided for @statsDecadeAfter2020.
  ///
  /// In en, this message translates to:
  /// **'2020 and later'**
  String get statsDecadeAfter2020;

  /// No description provided for @statsAverageRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} ★'**
  String statsAverageRating(String rating);

  /// No description provided for @statsSeriesProgression.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get statsSeriesProgression;

  /// No description provided for @statsSeriesProgressCount.
  ///
  /// In en, this message translates to:
  /// **'{watched} / {total} episodes ({percent}%)'**
  String statsSeriesProgressCount(int watched, int total, String percent);

  /// No description provided for @statsSeriesWatchedEpisodes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode} other{{count} episodes}}'**
  String statsSeriesWatchedEpisodes(int count);

  /// No description provided for @statsListsAndDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Lists and discovery'**
  String get statsListsAndDiscovery;

  /// No description provided for @statsWatchlistCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 title in Watchlist} other{{count} titles in Watchlist}}'**
  String statsWatchlistCount(int count);

  /// No description provided for @statsCustomListsCount.
  ///
  /// In en, this message translates to:
  /// **'{listsCount, plural, =1{1 custom list} other{{listsCount} custom lists}} ({itemsCount} titles)'**
  String statsCustomListsCount(int listsCount, int itemsCount);

  /// No description provided for @statsFooterDatedHistory.
  ///
  /// In en, this message translates to:
  /// **'Calculated on dated viewing history.'**
  String get statsFooterDatedHistory;

  /// No description provided for @statsMoviesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 movie} other{{count} movies}}'**
  String statsMoviesCount(int count);

  /// No description provided for @statsEpisodesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode} other{{count} episodes}}'**
  String statsEpisodesCount(int count);

  /// No description provided for @genreAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get genreAction;

  /// No description provided for @genreAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get genreAdventure;

  /// No description provided for @genreAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get genreAnimation;

  /// No description provided for @genreComedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get genreComedy;

  /// No description provided for @genreCrime.
  ///
  /// In en, this message translates to:
  /// **'Crime'**
  String get genreCrime;

  /// No description provided for @genreDocumentary.
  ///
  /// In en, this message translates to:
  /// **'Documentary'**
  String get genreDocumentary;

  /// No description provided for @genreDrama.
  ///
  /// In en, this message translates to:
  /// **'Drama'**
  String get genreDrama;

  /// No description provided for @genreFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get genreFamily;

  /// No description provided for @genreFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get genreFantasy;

  /// No description provided for @genreHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get genreHistory;

  /// No description provided for @genreHorror.
  ///
  /// In en, this message translates to:
  /// **'Horror'**
  String get genreHorror;

  /// No description provided for @genreMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get genreMusic;

  /// No description provided for @genreMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get genreMystery;

  /// No description provided for @genreRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get genreRomance;

  /// No description provided for @genreSciFi.
  ///
  /// In en, this message translates to:
  /// **'Sci-Fi'**
  String get genreSciFi;

  /// No description provided for @genreTvMovie.
  ///
  /// In en, this message translates to:
  /// **'TV Movie'**
  String get genreTvMovie;

  /// No description provided for @genreThriller.
  ///
  /// In en, this message translates to:
  /// **'Thriller'**
  String get genreThriller;

  /// No description provided for @genreWar.
  ///
  /// In en, this message translates to:
  /// **'War'**
  String get genreWar;

  /// No description provided for @genreWestern.
  ///
  /// In en, this message translates to:
  /// **'Western'**
  String get genreWestern;

  /// No description provided for @genreActionAdventure.
  ///
  /// In en, this message translates to:
  /// **'Action & Adventure'**
  String get genreActionAdventure;

  /// No description provided for @genreKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get genreKids;

  /// No description provided for @genreNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get genreNews;

  /// No description provided for @genreReality.
  ///
  /// In en, this message translates to:
  /// **'Reality'**
  String get genreReality;

  /// No description provided for @genreSciFiFantasy.
  ///
  /// In en, this message translates to:
  /// **'Sci-Fi & Fantasy'**
  String get genreSciFiFantasy;

  /// No description provided for @genreSoap.
  ///
  /// In en, this message translates to:
  /// **'Soap'**
  String get genreSoap;

  /// No description provided for @genreTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get genreTalk;

  /// No description provided for @genreWarPolitics.
  ///
  /// In en, this message translates to:
  /// **'War & Politics'**
  String get genreWarPolitics;

  /// No description provided for @discoveryFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Discovery Filters'**
  String get discoveryFiltersTitle;

  /// No description provided for @discoveryBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get discoveryBoth;

  /// No description provided for @discoveryGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get discoveryGenres;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @discoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoveryTitle;

  /// No description provided for @discoveryClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get discoveryClearFilters;

  /// No description provided for @releaseEpisodeTba.
  ///
  /// In en, this message translates to:
  /// **'Episode — date TBA'**
  String get releaseEpisodeTba;

  /// No description provided for @releaseReturning.
  ///
  /// In en, this message translates to:
  /// **'Returning — new season planned'**
  String get releaseReturning;

  /// No description provided for @releasePlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned — no release date'**
  String get releasePlanned;

  /// No description provided for @notifNoReleases.
  ///
  /// In en, this message translates to:
  /// **'No upcoming or recent releases.'**
  String get notifNoReleases;

  /// No description provided for @notifNoReleasesHint.
  ///
  /// In en, this message translates to:
  /// **'Movies and series on your watchlist or with alerts on show their releases here.'**
  String get notifNoReleasesHint;

  /// No description provided for @notifReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'{released, select, true{Released} other{Releases}}: {date}'**
  String notifReleaseDate(String released, String date);

  /// No description provided for @commonMarkAsSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark as seen'**
  String get commonMarkAsSeen;

  /// No description provided for @notifNoNextEpisodes.
  ///
  /// In en, this message translates to:
  /// **'No next episodes to track.'**
  String get notifNoNextEpisodes;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @detailOfflineSeason.
  ///
  /// In en, this message translates to:
  /// **'Cannot load season details while offline.'**
  String get detailOfflineSeason;

  /// No description provided for @detailNoHistoryToExport.
  ///
  /// In en, this message translates to:
  /// **'No history to export for this item.'**
  String get detailNoHistoryToExport;

  /// No description provided for @detailHistoryShareText.
  ///
  /// In en, this message translates to:
  /// **'Seen history for {title}'**
  String detailHistoryShareText(String title);

  /// No description provided for @detailSaveHistoryDialog.
  ///
  /// In en, this message translates to:
  /// **'Save History'**
  String get detailSaveHistoryDialog;

  /// No description provided for @detailSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String detailSaveFailed(String error);

  /// No description provided for @detailExportHistory.
  ///
  /// In en, this message translates to:
  /// **'Export history for this item'**
  String get detailExportHistory;

  /// No description provided for @detailProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {seen} / {total} episodes seen'**
  String detailProgress(int seen, int total);

  /// No description provided for @detailOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get detailOfflineMode;

  /// No description provided for @detailOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'Detailed information is unavailable without internet.'**
  String get detailOfflineMessage;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get commonTryAgain;

  /// No description provided for @detailSeasonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Season} other{{count} Seasons}}'**
  String detailSeasonCount(int count);

  /// No description provided for @detailEpisodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Episode} other{{count} Episodes}}'**
  String detailEpisodeCount(int count);

  /// No description provided for @detailOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get detailOverview;

  /// No description provided for @detailSeasons.
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get detailSeasons;

  /// No description provided for @detailSeasonName.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String detailSeasonName(int number);

  /// No description provided for @detailSeasonProgress.
  ///
  /// In en, this message translates to:
  /// **'{seen} / {total} episodes seen'**
  String detailSeasonProgress(int seen, int total);

  /// No description provided for @detailCast.
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get detailCast;

  /// No description provided for @detailSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar'**
  String get detailSimilar;

  /// No description provided for @detailRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get detailRecommendations;

  /// No description provided for @detailTrailers.
  ///
  /// In en, this message translates to:
  /// **'Trailers'**
  String get detailTrailers;

  /// No description provided for @statusReleased.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get statusReleased;

  /// No description provided for @statusReturning.
  ///
  /// In en, this message translates to:
  /// **'Returning Series'**
  String get statusReturning;

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get statusEnded;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @statusInProduction.
  ///
  /// In en, this message translates to:
  /// **'In Production'**
  String get statusInProduction;

  /// No description provided for @statusPostProduction.
  ///
  /// In en, this message translates to:
  /// **'Post Production'**
  String get statusPostProduction;

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get statusPlanned;

  /// No description provided for @statusRumored.
  ///
  /// In en, this message translates to:
  /// **'Rumored'**
  String get statusRumored;

  /// No description provided for @statusPilot.
  ///
  /// In en, this message translates to:
  /// **'Pilot'**
  String get statusPilot;

  /// No description provided for @seenEpisodesSeenTitle.
  ///
  /// In en, this message translates to:
  /// **'Episodes Seen'**
  String get seenEpisodesSeenTitle;

  /// No description provided for @seenSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get seenSeen;

  /// No description provided for @seenEpisodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode} other{{count} episodes}}'**
  String seenEpisodeCount(int count);

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @seenClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get seenClearHistory;

  /// No description provided for @seenClearHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all viewing history for \"{title}\"?'**
  String seenClearHistoryMessage(String title);

  /// No description provided for @seenClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get seenClearAll;

  /// No description provided for @seenAddViewing.
  ///
  /// In en, this message translates to:
  /// **'Add New Viewing'**
  String get seenAddViewing;

  /// No description provided for @seenNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No viewing history found for this item.'**
  String get seenNoHistory;

  /// No description provided for @seenRemoveAllHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove All History'**
  String get seenRemoveAllHistory;

  /// No description provided for @seenUseCalendar.
  ///
  /// In en, this message translates to:
  /// **'Use Calendar'**
  String get seenUseCalendar;

  /// No description provided for @seenTypeDate.
  ///
  /// In en, this message translates to:
  /// **'Type Date'**
  String get seenTypeDate;

  /// No description provided for @seenDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date (MM/DD/YYYY)'**
  String get seenDateLabel;

  /// No description provided for @seenDateHint.
  ///
  /// In en, this message translates to:
  /// **'12/31/2023'**
  String get seenDateHint;

  /// No description provided for @seenTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String seenTimeLabel(String time);

  /// No description provided for @seenCancelCaps.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get seenCancelCaps;

  /// No description provided for @seenInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid date (MM/DD/YYYY)'**
  String get seenInvalidDate;

  /// No description provided for @seenLogViewing.
  ///
  /// In en, this message translates to:
  /// **'LOG VIEWING'**
  String get seenLogViewing;

  /// No description provided for @likeUnlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get likeUnlike;

  /// No description provided for @likeLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeLike;

  /// No description provided for @notifyDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable notifications'**
  String get notifyDisable;

  /// No description provided for @notifyEnable.
  ///
  /// In en, this message translates to:
  /// **'Notify me on release'**
  String get notifyEnable;

  /// No description provided for @watchlistRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from watchlist'**
  String get watchlistRemove;

  /// No description provided for @watchlistAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to watchlist'**
  String get watchlistAdd;

  /// No description provided for @watchNext.
  ///
  /// In en, this message translates to:
  /// **'Watch Next: S{season} E{episode}'**
  String watchNext(int season, int episode);

  /// No description provided for @actorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load actor details: {error}'**
  String actorLoadFailed(String error);

  /// No description provided for @actorBiography.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get actorBiography;

  /// No description provided for @actorKnownFor.
  ///
  /// In en, this message translates to:
  /// **'Known For'**
  String get actorKnownFor;

  /// No description provided for @achievementsOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get achievementsOverall;

  /// No description provided for @achievementsCategoryMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get achievementsCategoryMovies;

  /// No description provided for @achievementsCategoryTv.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get achievementsCategoryTv;

  /// No description provided for @achievementsCategoryBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get achievementsCategoryBooks;

  /// No description provided for @achievementsCategoryDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get achievementsCategoryDiscovery;

  /// No description provided for @achievementsCategoryTogether.
  ///
  /// In en, this message translates to:
  /// **'Together'**
  String get achievementsCategoryTogether;

  /// No description provided for @achievementsCategoryRegularity.
  ///
  /// In en, this message translates to:
  /// **'Regularity'**
  String get achievementsCategoryRegularity;

  /// No description provided for @achievementsUnlockedCount.
  ///
  /// In en, this message translates to:
  /// **'You\'ve unlocked {unlocked} out of {total} badges'**
  String achievementsUnlockedCount(int unlocked, int total);

  /// No description provided for @achievementsUnlockedOn.
  ///
  /// In en, this message translates to:
  /// **'Unlocked on {date}'**
  String achievementsUnlockedOn(String date);

  /// No description provided for @achievementsChallengesCompleted.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} challenges completed'**
  String achievementsChallengesCompleted(int completed, int total);

  /// No description provided for @achievementsLevelProgress.
  ///
  /// In en, this message translates to:
  /// **'Level {unlocked}/{total}'**
  String achievementsLevelProgress(int unlocked, int total);

  /// No description provided for @achievementsLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level} · {title}'**
  String achievementsLevelTitle(int level, String title);

  /// No description provided for @achievementsNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next: {title} · {progress}'**
  String achievementsNextLevel(String title, String progress);

  /// No description provided for @achievementsAllLevelsCompleted.
  ///
  /// In en, this message translates to:
  /// **'All levels completed'**
  String get achievementsAllLevelsCompleted;

  /// No description provided for @achievementLevelUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Level {level} Unlocked!'**
  String achievementLevelUnlocked(int level);

  /// No description provided for @progressImportingAll.
  ///
  /// In en, this message translates to:
  /// **'Importing all data...'**
  String get progressImportingAll;

  /// No description provided for @progressDone.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get progressDone;

  /// No description provided for @progressError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String progressError(String error);

  /// No description provided for @progressRefetchingRuntimes.
  ///
  /// In en, this message translates to:
  /// **'Refetching missing runtimes...'**
  String get progressRefetchingRuntimes;

  /// No description provided for @progressRefetchingItem.
  ///
  /// In en, this message translates to:
  /// **'Refetching {title}...'**
  String progressRefetchingItem(String title);

  /// No description provided for @progressProcessingItem.
  ///
  /// In en, this message translates to:
  /// **'Processing {title}...'**
  String progressProcessingItem(String title);

  /// No description provided for @progressSavingEntries.
  ///
  /// In en, this message translates to:
  /// **'Saving entries...'**
  String get progressSavingEntries;

  /// No description provided for @progressImportComplete.
  ///
  /// In en, this message translates to:
  /// **'Import complete'**
  String get progressImportComplete;

  /// No description provided for @mediaKindMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get mediaKindMovie;

  /// No description provided for @mediaKindSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get mediaKindSeries;

  /// No description provided for @mediaKindBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get mediaKindBook;

  /// No description provided for @swiperTitle.
  ///
  /// In en, this message translates to:
  /// **'Swiper'**
  String get swiperTitle;

  /// No description provided for @swiperAddTo.
  ///
  /// In en, this message translates to:
  /// **'Add to'**
  String get swiperAddTo;

  /// No description provided for @swiperDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get swiperDiscard;

  /// No description provided for @swiperAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get swiperAdd;

  /// No description provided for @swiperUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get swiperUndo;

  /// No description provided for @swiperEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No more movies'**
  String get swiperEmptyTitle;

  /// No description provided for @swiperEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve gone through all available movies for now.'**
  String get swiperEmptyMessage;

  /// No description provided for @swiperSessionStats.
  ///
  /// In en, this message translates to:
  /// **'{added} added · {discarded} discarded'**
  String swiperSessionStats(int added, int discarded);

  /// No description provided for @swiperSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe mode in Discover'**
  String get swiperSettingTitle;

  /// No description provided for @swiperSettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show swipe mode to discover movies card by card'**
  String get swiperSettingSubtitle;

  /// No description provided for @swiperSagaBadge.
  ///
  /// In en, this message translates to:
  /// **'Saga ({count} movies)'**
  String swiperSagaBadge(int count);

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @offlineBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineBannerTitle;

  /// No description provided for @posterInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get posterInProgress;

  /// No description provided for @posterLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get posterLiked;

  /// No description provided for @posterRating.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating}'**
  String posterRating(String rating);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navTogether.
  ///
  /// In en, this message translates to:
  /// **'Together'**
  String get navTogether;

  /// No description provided for @navMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navMe;

  /// No description provided for @librarySectionLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get librarySectionLists;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tonight'**
  String get homeTitle;

  /// No description provided for @homeOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'releases will be refreshed when the network is back.'**
  String get homeOfflineMessage;

  /// No description provided for @homeResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeResume;

  /// No description provided for @homeEpisodeCode.
  ///
  /// In en, this message translates to:
  /// **'S{season} E{episode}'**
  String homeEpisodeCode(int season, int episode);

  /// No description provided for @homeNextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next: {episode}'**
  String homeNextEpisode(String episode);

  /// No description provided for @homeMarkEpisodeSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark {episode} of {title} as seen'**
  String homeMarkEpisodeSeen(String episode, String title);

  /// No description provided for @homeEpisodeSeenMessage.
  ///
  /// In en, this message translates to:
  /// **'{episode} seen · {title}'**
  String homeEpisodeSeenMessage(String episode, String title);

  /// No description provided for @homeTonightTitle.
  ///
  /// In en, this message translates to:
  /// **'To watch tonight'**
  String get homeTonightTitle;

  /// No description provided for @homeTonightOtherIdea.
  ///
  /// In en, this message translates to:
  /// **'Another idea'**
  String get homeTonightOtherIdea;

  /// No description provided for @homeTonightSource.
  ///
  /// In en, this message translates to:
  /// **'From your list \"{list}\" · {count, plural, =1{1 title not seen yet} other{{count} titles not seen yet}}'**
  String homeTonightSource(String list, int count);

  /// No description provided for @homeChooseTogether.
  ///
  /// In en, this message translates to:
  /// **'Choose together'**
  String get homeChooseTogether;

  /// No description provided for @homeChooseTogetherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare your lists and vote'**
  String get homeChooseTogetherSubtitle;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned tonight.'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add films or series to your list \"{list}\" to find them here.'**
  String homeEmptyMessage(String list);

  /// No description provided for @homeEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'Discover titles'**
  String get homeEmptyAction;

  /// No description provided for @homeAlsoInProgress.
  ///
  /// In en, this message translates to:
  /// **'Also in progress · {count}'**
  String homeAlsoInProgress(int count);

  /// No description provided for @homeSeeAllCount.
  ///
  /// In en, this message translates to:
  /// **'See all ({count})'**
  String homeSeeAllCount(int count);

  /// No description provided for @homeRecentAreInResume.
  ///
  /// In en, this message translates to:
  /// **'The most recent ones are in \"Resume\".'**
  String get homeRecentAreInResume;

  /// No description provided for @homeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All · {count}'**
  String homeFilterAll(int count);

  /// No description provided for @homeFilterSeries.
  ///
  /// In en, this message translates to:
  /// **'Series · {count}'**
  String homeFilterSeries(int count);

  /// No description provided for @homeFilterBooks.
  ///
  /// In en, this message translates to:
  /// **'Books · {count}'**
  String homeFilterBooks(int count);

  /// No description provided for @homeMoreInProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} more, see all'**
  String homeMoreInProgress(int count);

  /// No description provided for @homePausedTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} paused'**
  String homePausedTitle(int count);

  /// No description provided for @homePausedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No activity for more than {days} days'**
  String homePausedSubtitle(int days);

  /// No description provided for @homeAgoToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get homeAgoToday;

  /// No description provided for @homeAgoYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get homeAgoYesterday;

  /// No description provided for @homeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String homeAgoDays(int count);

  /// No description provided for @homeAgoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} wk ago'**
  String homeAgoWeeks(int count);

  /// No description provided for @homeAgoMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} mo ago'**
  String homeAgoMonths(int count);

  /// No description provided for @homeConnectTmdbTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect TMDB'**
  String get homeConnectTmdbTitle;

  /// No description provided for @homeConnectTmdbMessage.
  ///
  /// In en, this message translates to:
  /// **'MediaVore gets posters, release dates and new episodes from TMDB. You need a free personal key.'**
  String get homeConnectTmdbMessage;

  /// No description provided for @homeConnectTmdbAction.
  ///
  /// In en, this message translates to:
  /// **'Connect to TMDB'**
  String get homeConnectTmdbAction;

  /// No description provided for @discoverModeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get discoverModeExplore;

  /// No description provided for @discoverModeSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get discoverModeSwipe;

  /// No description provided for @discoverSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Films, series'**
  String get discoverSearchHint;

  /// No description provided for @discoverSearchHintWithBooks.
  ///
  /// In en, this message translates to:
  /// **'Films, series, books'**
  String get discoverSearchHintWithBooks;

  /// No description provided for @discoverSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get discoverSearchLabel;

  /// No description provided for @discoverSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the search'**
  String get discoverSearchClear;

  /// No description provided for @discoverTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get discoverTypeAll;

  /// No description provided for @discoverTypeFilms.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get discoverTypeFilms;

  /// No description provided for @discoverTypeSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get discoverTypeSeries;

  /// No description provided for @discoverTypeBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get discoverTypeBooks;

  /// No description provided for @discoverTrendingWeek.
  ///
  /// In en, this message translates to:
  /// **'Trending this week'**
  String get discoverTrendingWeek;

  /// No description provided for @discoverResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get discoverResults;

  /// No description provided for @discoverResultsCount.
  ///
  /// In en, this message translates to:
  /// **'Results · {count}'**
  String discoverResultsCount(int count);

  /// No description provided for @discoverNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results with these filters.'**
  String get discoverNoResults;

  /// No description provided for @discoverNoResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\".'**
  String discoverNoResultsFor(String query);

  /// No description provided for @discoverOfflineMessage.
  ///
  /// In en, this message translates to:
  /// **'check your connection and try again. Your lists and your history remain available.'**
  String get discoverOfflineMessage;

  /// No description provided for @discoverPeopleSection.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get discoverPeopleSection;

  /// No description provided for @discoverBecauseYouLiked.
  ///
  /// In en, this message translates to:
  /// **'Because you liked {title}'**
  String discoverBecauseYouLiked(String title);

  /// No description provided for @discoverBecauseYouWatched.
  ///
  /// In en, this message translates to:
  /// **'Because you watched {title}'**
  String discoverBecauseYouWatched(String title);

  /// No description provided for @discoverConnectTmdb.
  ///
  /// In en, this message translates to:
  /// **'Connect to TMDB'**
  String get discoverConnectTmdb;

  /// No description provided for @libraryTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryTypeAll;

  /// No description provided for @libraryTypeChip.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count}'**
  String libraryTypeChip(String label, int count);

  /// No description provided for @libraryListRowLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, {count, plural, =0{no items} =1{1 item} other{{count} items}}, {films, plural, =0{no movies} =1{1 movie} other{{films} movies}}, {series, plural, =0{no series} =1{1 series} other{{series} series}}'**
  String libraryListRowLabel(String name, int count, int films, int series);

  /// No description provided for @libraryListImported.
  ///
  /// In en, this message translates to:
  /// **'List “{name}” added'**
  String libraryListImported(String name);

  /// No description provided for @libraryListNameTaken.
  ///
  /// In en, this message translates to:
  /// **'A list named “{name}” already exists'**
  String libraryListNameTaken(String name);

  /// No description provided for @profileActiveDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No active days in the last 30 days} =1{1 active day in the last 30 days} other{{count} active days in the last 30 days}}'**
  String profileActiveDays(int count);

  /// No description provided for @profileMoviesWatched.
  ///
  /// In en, this message translates to:
  /// **'Movies watched'**
  String get profileMoviesWatched;

  /// No description provided for @profileEpisodesAndScreen.
  ///
  /// In en, this message translates to:
  /// **'Episodes & screen'**
  String get profileEpisodesAndScreen;

  /// No description provided for @profileScreenTime.
  ///
  /// In en, this message translates to:
  /// **'{hours}h screen time'**
  String profileScreenTime(int hours);

  /// No description provided for @profileAllStats.
  ///
  /// In en, this message translates to:
  /// **'All statistics'**
  String get profileAllStats;

  /// No description provided for @profileAchievementsSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all · {unlocked} of {total}'**
  String profileAchievementsSeeAll(int unlocked, int total);

  /// No description provided for @profileUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get profileUnlocked;

  /// No description provided for @listsIncomingSharedTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared List Received'**
  String get listsIncomingSharedTitle;

  /// No description provided for @listsIncomingSharedMessage.
  ///
  /// In en, this message translates to:
  /// **'The shared list \"{name}\" contains {count, plural, =1{1 title} other{{count} titles}}. What would you like to do?'**
  String listsIncomingSharedMessage(String name, int count);

  /// No description provided for @listsCompareWithMine.
  ///
  /// In en, this message translates to:
  /// **'Compare with one of my lists'**
  String get listsCompareWithMine;

  /// No description provided for @listsImportOptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Import into library'**
  String get listsImportOptionTitle;

  /// No description provided for @listsCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'List Intersection'**
  String get listsCompareTitle;

  /// No description provided for @listsCompareCommonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No titles in common} =1{1 title in common} other{{count} titles in common}}'**
  String listsCompareCommonCount(int count);

  /// No description provided for @listsCompareHideSeen.
  ///
  /// In en, this message translates to:
  /// **'Hide watched'**
  String get listsCompareHideSeen;

  /// No description provided for @listsCompareEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No common titles'**
  String get listsCompareEmptyTitle;

  /// No description provided for @listsCompareEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No movies or TV shows appear in both \"{otherList}\" and \"{myList}\".'**
  String listsCompareEmptyMessage(String otherList, String myList);

  /// No description provided for @listsCompareSaveAsList.
  ///
  /// In en, this message translates to:
  /// **'Save as new list ({count})'**
  String listsCompareSaveAsList(int count);

  /// No description provided for @listsCompareSaveAsListSuccess.
  ///
  /// In en, this message translates to:
  /// **'List created successfully!'**
  String get listsCompareSaveAsListSuccess;

  /// No description provided for @listsCompareShareIntersection.
  ///
  /// In en, this message translates to:
  /// **'Share Common Selection'**
  String get listsCompareShareIntersection;

  /// No description provided for @listsCompareDefaultIntersectionName.
  ///
  /// In en, this message translates to:
  /// **'Common with {name}'**
  String listsCompareDefaultIntersectionName(String name);

  /// No description provided for @mediaTypeMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get mediaTypeMovie;

  /// No description provided for @mediaTypeTv.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get mediaTypeTv;

  /// No description provided for @detailEpisodeRuntime.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String detailEpisodeRuntime(int minutes);

  /// No description provided for @detailSeenTimes.
  ///
  /// In en, this message translates to:
  /// **'Seen {count} times'**
  String detailSeenTimes(int count);

  /// No description provided for @detailSeriesFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get detailSeriesFinished;

  /// Button label to start a new viewing cycle for a completed series
  ///
  /// In en, this message translates to:
  /// **'Rewatch series'**
  String get rewatchSeriesAction;

  /// No description provided for @rewatchStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'{cycle, select, 2{2nd} 3{3rd} other{{cycle}th}} watch started · previous viewings are preserved'**
  String rewatchStartedMessage(String cycle);

  /// No description provided for @episodeAlreadySeenOn.
  ///
  /// In en, this message translates to:
  /// **'Already seen on {date}'**
  String episodeAlreadySeenOn(String date);

  /// No description provided for @detailSeriesRewatching.
  ///
  /// In en, this message translates to:
  /// **'{cycle, select, 2{2nd} 3{3rd} other{{cycle}th}} watch · Next: S{season} E{episode}'**
  String detailSeriesRewatching(String cycle, int season, int episode);

  /// No description provided for @detailSeriesWatchedTimes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Watched 1 time} other{Watched {count} times}}'**
  String detailSeriesWatchedTimes(int count);

  /// No description provided for @detailMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get detailMoreActions;

  /// No description provided for @detailShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get detailShare;

  /// No description provided for @detailShareHint.
  ///
  /// In en, this message translates to:
  /// **'Link to the title page'**
  String get detailShareHint;

  /// No description provided for @detailAddToList.
  ///
  /// In en, this message translates to:
  /// **'Add to “{name}”'**
  String detailAddToList(String name);

  /// No description provided for @detailInListRemove.
  ///
  /// In en, this message translates to:
  /// **'In “{name}”, tap to remove'**
  String detailInListRemove(String name);

  /// No description provided for @detailChooseList.
  ///
  /// In en, this message translates to:
  /// **'Choose a list'**
  String get detailChooseList;

  /// No description provided for @detailChooseListOthers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Choose another list} =1{Choose another list (in 1 other)} other{Choose another list (in {count} others)}}'**
  String detailChooseListOthers(int count);

  /// No description provided for @detailAddedToList.
  ///
  /// In en, this message translates to:
  /// **'Added to “{name}”'**
  String detailAddedToList(String name);

  /// No description provided for @detailRemovedFromList.
  ///
  /// In en, this message translates to:
  /// **'Removed from “{name}”'**
  String detailRemovedFromList(String name);

  /// No description provided for @detailReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get detailReadMore;

  /// No description provided for @detailReadLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get detailReadLess;

  /// No description provided for @detailInfos.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get detailInfos;

  /// No description provided for @detailInfoDirection.
  ///
  /// In en, this message translates to:
  /// **'Directed by'**
  String get detailInfoDirection;

  /// No description provided for @detailInfoCreation.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get detailInfoCreation;

  /// No description provided for @detailOriginalTitle.
  ///
  /// In en, this message translates to:
  /// **'Original title'**
  String get detailOriginalTitle;

  /// No description provided for @detailCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get detailCountry;

  /// No description provided for @detailLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get detailLanguage;

  /// No description provided for @detailCountryName.
  ///
  /// In en, this message translates to:
  /// **'{code, select, US{United States} GB{United Kingdom} FR{France} DE{Germany} IT{Italy} ES{Spain} CA{Canada} JP{Japan} KR{South Korea} CN{China} HK{Hong Kong} TW{Taiwan} IN{India} AU{Australia} NZ{New Zealand} BE{Belgium} CH{Switzerland} NL{Netherlands} SE{Sweden} NO{Norway} DK{Denmark} FI{Finland} IS{Iceland} IE{Ireland} PT{Portugal} BR{Brazil} MX{Mexico} AR{Argentina} CL{Chile} CO{Colombia} RU{Russia} PL{Poland} CZ{Czechia} AT{Austria} HU{Hungary} GR{Greece} TR{Turkey} IL{Israel} IR{Iran} EG{Egypt} ZA{South Africa} TH{Thailand} ID{Indonesia} PH{Philippines} UA{Ukraine} RO{Romania} LU{Luxembourg} other{{code}}}'**
  String detailCountryName(String code);

  /// No description provided for @detailLanguageName.
  ///
  /// In en, this message translates to:
  /// **'{code, select, en{English} fr{French} de{German} it{Italian} es{Spanish} pt{Portuguese} ja{Japanese} ko{Korean} zh{Chinese} cn{Cantonese} hi{Hindi} ru{Russian} sv{Swedish} no{Norwegian} da{Danish} fi{Finnish} nl{Dutch} pl{Polish} tr{Turkish} ar{Arabic} he{Hebrew} fa{Persian} th{Thai} id{Indonesian} el{Greek} cs{Czech} hu{Hungarian} ro{Romanian} uk{Ukrainian} is{Icelandic} ta{Tamil} te{Telugu} tl{Tagalog} xx{No language} other{{code}}}'**
  String detailLanguageName(String code);

  /// No description provided for @detailInYourLists.
  ///
  /// In en, this message translates to:
  /// **'In your lists: {lists}'**
  String detailInYourLists(String lists);

  /// No description provided for @detailRating.
  ///
  /// In en, this message translates to:
  /// **'{rating} out of 10 on TMDB'**
  String detailRating(String rating);

  /// No description provided for @inProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'In progress · {count}'**
  String inProgressTitle(int count);

  /// No description provided for @inProgressPausedChip.
  ///
  /// In en, this message translates to:
  /// **'Paused · {count}'**
  String inProgressPausedChip(int count);

  /// No description provided for @inProgressSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get inProgressSortRecent;

  /// No description provided for @inProgressSortAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done'**
  String get inProgressSortAlmostDone;

  /// No description provided for @inProgressSortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'A–Z'**
  String get inProgressSortAlphabetical;

  /// No description provided for @inProgressEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters.'**
  String get inProgressEmptyFiltered;

  /// No description provided for @inProgressMoreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions for {title}'**
  String inProgressMoreActions(String title);

  /// No description provided for @inProgressRemoveFromQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'Remove from quick add'**
  String get inProgressRemoveFromQuickAdd;

  /// No description provided for @inProgressRemoveFromQuickAddSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The series will no longer appear in In progress'**
  String get inProgressRemoveFromQuickAddSubtitle;

  /// No description provided for @inProgressOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get inProgressOpenDetails;

  /// No description provided for @inProgressRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Series removed from quick add'**
  String get inProgressRemovedMessage;

  /// No description provided for @inProgressRemovedSection.
  ///
  /// In en, this message translates to:
  /// **'Removed from quick add · {count}'**
  String inProgressRemovedSection(int count);

  /// No description provided for @inProgressRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get inProgressRestore;

  /// No description provided for @inProgressRestoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Restore {title}'**
  String inProgressRestoreLabel(String title);

  /// No description provided for @inProgressRestoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Series restored'**
  String get inProgressRestoredMessage;

  /// No description provided for @debugMissingEpisodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug — missing episodes'**
  String get debugMissingEpisodesTitle;

  /// No description provided for @debugMissingEpisodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expected next episodes that are not shown above.'**
  String get debugMissingEpisodesSubtitle;

  /// No description provided for @debugRecompute.
  ///
  /// In en, this message translates to:
  /// **'Recompute'**
  String get debugRecompute;

  /// No description provided for @debugNothingOmitted.
  ///
  /// In en, this message translates to:
  /// **'Nothing omitted.'**
  String get debugNothingOmitted;

  /// No description provided for @debugGroupCount.
  ///
  /// In en, this message translates to:
  /// **'{title} · {count}'**
  String debugGroupCount(String title, int count);

  /// No description provided for @debugTitleWithEpisode.
  ///
  /// In en, this message translates to:
  /// **'{title} · {episode}'**
  String debugTitleWithEpisode(String title, String episode);

  /// No description provided for @debugTitleAfterEpisode.
  ///
  /// In en, this message translates to:
  /// **'{title} · after {episode}'**
  String debugTitleAfterEpisode(String title, String episode);

  /// No description provided for @debugQuickAddOptedOut.
  ///
  /// In en, this message translates to:
  /// **'Removed from quick add'**
  String get debugQuickAddOptedOut;

  /// No description provided for @debugQuickAddOptedOutDetail.
  ///
  /// In en, this message translates to:
  /// **'Removed manually'**
  String get debugQuickAddOptedOutDetail;

  /// No description provided for @debugQuickAddNotReleased.
  ///
  /// In en, this message translates to:
  /// **'Next episode not aired yet'**
  String get debugQuickAddNotReleased;

  /// No description provided for @debugQuickAddNotReleasedDetail.
  ///
  /// In en, this message translates to:
  /// **'Airs on {date}'**
  String debugQuickAddNotReleasedDetail(String date);

  /// No description provided for @debugQuickAddNotReleasedUnknown.
  ///
  /// In en, this message translates to:
  /// **'Air date unknown'**
  String get debugQuickAddNotReleasedUnknown;

  /// No description provided for @debugQuickAddNotPopulated.
  ///
  /// In en, this message translates to:
  /// **'Not added to quick add'**
  String get debugQuickAddNotPopulated;

  /// No description provided for @debugQuickAddNotPopulatedDetail.
  ///
  /// In en, this message translates to:
  /// **'Aired episode missing from quick add: try Recompute'**
  String get debugQuickAddNotPopulatedDetail;

  /// No description provided for @debugQuickAddNoAirDate.
  ///
  /// In en, this message translates to:
  /// **'No air date'**
  String get debugQuickAddNoAirDate;

  /// No description provided for @debugQuickAddNoAirDateDetail.
  ///
  /// In en, this message translates to:
  /// **'The episode has no known air date'**
  String get debugQuickAddNoAirDateDetail;

  /// No description provided for @debugQuickAddNoCacheData.
  ///
  /// In en, this message translates to:
  /// **'Season data not cached'**
  String get debugQuickAddNoCacheData;

  /// No description provided for @debugQuickAddNoCacheDataDetail.
  ///
  /// In en, this message translates to:
  /// **'Tap Recompute to fetch the season'**
  String get debugQuickAddNoCacheDataDetail;

  /// No description provided for @upcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming · {count}'**
  String upcomingTitle(int count);

  /// No description provided for @upcomingGroupReleased.
  ///
  /// In en, this message translates to:
  /// **'Already released'**
  String get upcomingGroupReleased;

  /// No description provided for @upcomingGroupThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get upcomingGroupThisWeek;

  /// No description provided for @upcomingGroupThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get upcomingGroupThisMonth;

  /// No description provided for @upcomingGroupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get upcomingGroupLater;

  /// No description provided for @upcomingGroupCount.
  ///
  /// In en, this message translates to:
  /// **'{label} · {count}'**
  String upcomingGroupCount(String label, int count);

  /// No description provided for @upcomingUndatedRow.
  ///
  /// In en, this message translates to:
  /// **'{count} without a date'**
  String upcomingUndatedRow(int count);

  /// No description provided for @upcomingUndatedRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Renewed, planned, episodes to be dated'**
  String get upcomingUndatedRowSubtitle;

  /// No description provided for @upcomingUndatedSection.
  ///
  /// In en, this message translates to:
  /// **'No date · {count}'**
  String upcomingUndatedSection(int count);

  /// No description provided for @upcomingNothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned.'**
  String get upcomingNothingPlanned;

  /// No description provided for @upcomingDebugRow.
  ///
  /// In en, this message translates to:
  /// **'Debug · {count, plural, =1{1 hidden release} other{{count} hidden releases}}'**
  String upcomingDebugRow(int count);

  /// No description provided for @upcomingDebugRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See the reasons'**
  String get upcomingDebugRowSubtitle;

  /// No description provided for @upcomingMarkSeen.
  ///
  /// In en, this message translates to:
  /// **'Mark {title} as seen'**
  String upcomingMarkSeen(String title);

  /// No description provided for @upcomingSeenMessage.
  ///
  /// In en, this message translates to:
  /// **'Seen · {title}'**
  String upcomingSeenMessage(String title);

  /// No description provided for @upcomingDisableAlert.
  ///
  /// In en, this message translates to:
  /// **'Disable the alert'**
  String get upcomingDisableAlert;

  /// No description provided for @upcomingDisableAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The title will no longer appear in Upcoming'**
  String get upcomingDisableAlertSubtitle;

  /// No description provided for @upcomingAlertDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Alert disabled · {title}'**
  String upcomingAlertDisabledMessage(String title);

  /// No description provided for @debugHiddenReleasesTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug — hidden releases'**
  String get debugHiddenReleasesTitle;

  /// No description provided for @debugHiddenReleasesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These items exist in the database but are omitted above.'**
  String get debugHiddenReleasesSubtitle;

  /// No description provided for @debugReleaseAlreadySeen.
  ///
  /// In en, this message translates to:
  /// **'Already seen'**
  String get debugReleaseAlreadySeen;

  /// No description provided for @debugReleaseAlreadySeenDetail.
  ///
  /// In en, this message translates to:
  /// **'Already in the history'**
  String get debugReleaseAlreadySeenDetail;

  /// No description provided for @debugReleaseTooOld.
  ///
  /// In en, this message translates to:
  /// **'Aired more than {days} days ago'**
  String debugReleaseTooOld(int days);

  /// No description provided for @debugReleaseTooOldDetail.
  ///
  /// In en, this message translates to:
  /// **'Stored air date: {date}'**
  String debugReleaseTooOldDetail(String date);

  /// No description provided for @debugReleaseNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date stored'**
  String get debugReleaseNoDate;

  /// No description provided for @listsSortOrderManual.
  ///
  /// In en, this message translates to:
  /// **'Manual order'**
  String get listsSortOrderManual;

  /// No description provided for @listsSortOrderReleaseDate.
  ///
  /// In en, this message translates to:
  /// **'Release date'**
  String get listsSortOrderReleaseDate;

  /// No description provided for @listsSortOrderShuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get listsSortOrderShuffle;

  /// No description provided for @listsSortOrderReversed.
  ///
  /// In en, this message translates to:
  /// **'{order} (reversed)'**
  String listsSortOrderReversed(String order);

  /// No description provided for @listsHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 items} =1{1 item} other{{count} items}} · {order}'**
  String listsHeaderSubtitle(int count, String order);

  /// No description provided for @listsDisplayGrid2.
  ///
  /// In en, this message translates to:
  /// **'Grid (2 columns)'**
  String get listsDisplayGrid2;

  /// No description provided for @listsDisplayGrid3.
  ///
  /// In en, this message translates to:
  /// **'Grid (3 columns)'**
  String get listsDisplayGrid3;

  /// No description provided for @listsDisplayGrid4.
  ///
  /// In en, this message translates to:
  /// **'Grid (4 columns)'**
  String get listsDisplayGrid4;

  /// No description provided for @listsDisplayDetailedList.
  ///
  /// In en, this message translates to:
  /// **'Detailed list'**
  String get listsDisplayDetailedList;

  /// No description provided for @listsActionShare.
  ///
  /// In en, this message translates to:
  /// **'Share list'**
  String get listsActionShare;

  /// No description provided for @listsActionSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get listsActionSelect;

  /// No description provided for @listsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get listsSelectAll;

  /// No description provided for @listsDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get listsDeselectAll;

  /// No description provided for @listsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get listsRemove;

  /// No description provided for @listsRemovedNotification.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item removed} other{{count} items removed}}'**
  String listsRemovedNotification(int count);

  /// No description provided for @listsFillBySwiping.
  ///
  /// In en, this message translates to:
  /// **'Fill by swiping'**
  String get listsFillBySwiping;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @filtersSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get filtersSortBy;

  /// No description provided for @filtersSortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get filtersSortRelevance;

  /// No description provided for @filtersSortRating.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get filtersSortRating;

  /// No description provided for @filtersSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Most recent'**
  String get filtersSortRecent;

  /// No description provided for @filtersSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get filtersSortOldest;

  /// No description provided for @filtersPeriod.
  ///
  /// In en, this message translates to:
  /// **'Release year'**
  String get filtersPeriod;

  /// No description provided for @filtersPeriodAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filtersPeriodAll;

  /// No description provided for @filtersPeriodBefore1990.
  ///
  /// In en, this message translates to:
  /// **'Before 1990'**
  String get filtersPeriodBefore1990;

  /// No description provided for @filtersPeriod1990s.
  ///
  /// In en, this message translates to:
  /// **'1990–1999'**
  String get filtersPeriod1990s;

  /// No description provided for @filtersPeriod2000s.
  ///
  /// In en, this message translates to:
  /// **'2000–2009'**
  String get filtersPeriod2000s;

  /// No description provided for @filtersPeriod2010s.
  ///
  /// In en, this message translates to:
  /// **'2010–2019'**
  String get filtersPeriod2010s;

  /// No description provided for @filtersPeriod2020plus.
  ///
  /// In en, this message translates to:
  /// **'2020 and later'**
  String get filtersPeriod2020plus;

  /// No description provided for @filtersRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimum rating'**
  String get filtersRatingTitle;

  /// No description provided for @filtersRatingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Movies and TV shows'**
  String get filtersRatingSubtitle;

  /// No description provided for @filtersRatingAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filtersRatingAll;

  /// No description provided for @filtersRating7Plus.
  ///
  /// In en, this message translates to:
  /// **'7+'**
  String get filtersRating7Plus;

  /// No description provided for @filtersRating8Plus.
  ///
  /// In en, this message translates to:
  /// **'8+'**
  String get filtersRating8Plus;

  /// No description provided for @filtersDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get filtersDurationTitle;

  /// No description provided for @filtersDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Movies only'**
  String get filtersDurationSubtitle;

  /// No description provided for @filtersDurationNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable to TV shows'**
  String get filtersDurationNotApplicable;

  /// No description provided for @filtersDurationAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filtersDurationAll;

  /// No description provided for @filtersDurationUnder105.
  ///
  /// In en, this message translates to:
  /// **'Under 1h 45m'**
  String get filtersDurationUnder105;

  /// No description provided for @filtersDuration105To150.
  ///
  /// In en, this message translates to:
  /// **'1h 45m to 2h 30m'**
  String get filtersDuration105To150;

  /// No description provided for @filtersDurationOver150.
  ///
  /// In en, this message translates to:
  /// **'Over 2h 30m'**
  String get filtersDurationOver150;

  /// No description provided for @filtersHideSeen.
  ///
  /// In en, this message translates to:
  /// **'Hide what I\'ve already seen or read'**
  String get filtersHideSeen;

  /// No description provided for @filtersClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get filtersClearAll;

  /// No description provided for @filtersShowResults.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get filtersShowResults;

  /// No description provided for @filtersShowNResults.
  ///
  /// In en, this message translates to:
  /// **'Show {count} results'**
  String filtersShowNResults(int count);

  /// No description provided for @filtersChipSort.
  ///
  /// In en, this message translates to:
  /// **'Sort: {sort}'**
  String filtersChipSort(String sort);

  /// No description provided for @filtersChipRating.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating}+'**
  String filtersChipRating(String rating);

  /// No description provided for @filtersChipHideSeen.
  ///
  /// In en, this message translates to:
  /// **'Unseen'**
  String get filtersChipHideSeen;

  /// No description provided for @historyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get historyYesterday;

  /// No description provided for @historyDayHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String historyDayHeaderSubtitle(int count);

  /// No description provided for @historyModeChronologicalHint.
  ///
  /// In en, this message translates to:
  /// **'Chronological view'**
  String get historyModeChronologicalHint;

  /// No description provided for @historyModeLibraryHint.
  ///
  /// In en, this message translates to:
  /// **'One entry per title'**
  String get historyModeLibraryHint;

  /// No description provided for @historyActionOpenDetail.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get historyActionOpenDetail;

  /// No description provided for @historyActionDeleteViewing.
  ///
  /// In en, this message translates to:
  /// **'Delete this viewing'**
  String get historyActionDeleteViewing;

  /// No description provided for @historyTimesSeen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Seen once} other{Seen {count} times}}'**
  String historyTimesSeen(int count);

  /// No description provided for @historyTvLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{episodesSeen, plural, =1{1 episode seen} other{{episodesSeen} episodes seen}} · {entries, plural, =1{1 entry} other{{entries} entries}}'**
  String historyTvLibrarySubtitle(int episodesSeen, int entries);

  /// No description provided for @historyEpisodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'S{season} E{episode}'**
  String historyEpisodeSubtitle(int season, int episode);

  /// No description provided for @historySegmentHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historySegmentHistory;

  /// No description provided for @historySegmentLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get historySegmentLibrary;

  /// No description provided for @historySortRecent.
  ///
  /// In en, this message translates to:
  /// **'Date (newest)'**
  String get historySortRecent;

  /// No description provided for @historySortOldest.
  ///
  /// In en, this message translates to:
  /// **'Date (oldest)'**
  String get historySortOldest;

  /// No description provided for @historySortTitleAsc.
  ///
  /// In en, this message translates to:
  /// **'Title (A–Z)'**
  String get historySortTitleAsc;

  /// No description provided for @historySortTitleDesc.
  ///
  /// In en, this message translates to:
  /// **'Title (Z–A)'**
  String get historySortTitleDesc;

  /// No description provided for @settingsSectionTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get settingsSectionTracking;

  /// No description provided for @settingsAdvancedTracking.
  ///
  /// In en, this message translates to:
  /// **'Advanced tracking'**
  String get settingsAdvancedTracking;

  /// No description provided for @settingsAdvancedTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose viewing date and time, edit past viewing logs'**
  String get settingsAdvancedTrackingSubtitle;

  /// No description provided for @commonMarkAsSeenWithDots.
  ///
  /// In en, this message translates to:
  /// **'Mark as seen…'**
  String get commonMarkAsSeenWithDots;

  /// No description provided for @seenRewatchAction.
  ///
  /// In en, this message translates to:
  /// **'Rewatch'**
  String get seenRewatchAction;

  /// No description provided for @seenRewatchActionWithDots.
  ///
  /// In en, this message translates to:
  /// **'Rewatch…'**
  String get seenRewatchActionWithDots;

  /// No description provided for @seenSummaryOnce.
  ///
  /// In en, this message translates to:
  /// **'Seen once · on {date}'**
  String seenSummaryOnce(String date);

  /// No description provided for @seenSummaryMultiple.
  ///
  /// In en, this message translates to:
  /// **'Seen {count} times · last on {date}'**
  String seenSummaryMultiple(int count, String date);

  /// No description provided for @seenAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Marked as seen · {title}'**
  String seenAddedMessage(String title);

  /// No description provided for @seenFutureDateError.
  ///
  /// In en, this message translates to:
  /// **'Viewing date cannot be in the future'**
  String get seenFutureDateError;

  /// No description provided for @seenOrdinal.
  ///
  /// In en, this message translates to:
  /// **'{ordinal, select, 1{1st} 2{2nd} 3{3rd} other{{ordinal}th}} viewing'**
  String seenOrdinal(String ordinal);

  /// No description provided for @seenEditViewing.
  ///
  /// In en, this message translates to:
  /// **'Edit date'**
  String get seenEditViewing;

  /// No description provided for @seenVisionnagesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Viewings'**
  String get seenVisionnagesSectionTitle;

  /// No description provided for @settingsPreviousEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Unseen previous episodes'**
  String get settingsPreviousEpisodes;

  /// No description provided for @settingsPreviousEpisodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Behavior when marking an episode while earlier episodes are unseen'**
  String get settingsPreviousEpisodesSubtitle;

  /// No description provided for @settingsPreviousEpisodesAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get settingsPreviousEpisodesAsk;

  /// No description provided for @settingsPreviousEpisodesAll.
  ///
  /// In en, this message translates to:
  /// **'All seen'**
  String get settingsPreviousEpisodesAll;

  /// No description provided for @settingsPreviousEpisodesOne.
  ///
  /// In en, this message translates to:
  /// **'Leave unseen'**
  String get settingsPreviousEpisodesOne;

  /// No description provided for @seenPreviousUnseenPrompt.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 previous episode is unseen. Mark it as seen too?} other{{count} previous episodes are unseen. Mark them as seen too?}}'**
  String seenPreviousUnseenPrompt(int count);

  /// No description provided for @seenPreviousMarkAll.
  ///
  /// In en, this message translates to:
  /// **'Yes, mark all as seen'**
  String get seenPreviousMarkAll;

  /// No description provided for @seenPreviousOnlyThis.
  ///
  /// In en, this message translates to:
  /// **'No, only this episode'**
  String get seenPreviousOnlyThis;

  /// No description provided for @seenRememberChoice.
  ///
  /// In en, this message translates to:
  /// **'Remember my choice'**
  String get seenRememberChoice;

  /// No description provided for @seenBatchAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Marked as seen · {count, plural, =1{1 episode} other{{count} episodes}}'**
  String seenBatchAddedMessage(int count);

  /// No description provided for @detailWhereToWatch.
  ///
  /// In en, this message translates to:
  /// **'Where to watch'**
  String get detailWhereToWatch;

  /// No description provided for @detailWatchFlatrate.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get detailWatchFlatrate;

  /// No description provided for @detailWatchRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get detailWatchRent;

  /// No description provided for @detailWatchBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get detailWatchBuy;

  /// No description provided for @detailWatchFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get detailWatchFree;

  /// No description provided for @detailWatchJustWatchAttribution.
  ///
  /// In en, this message translates to:
  /// **'Data provided by JustWatch'**
  String get detailWatchJustWatchAttribution;

  /// No description provided for @settingsWatchProvidersCountry.
  ///
  /// In en, this message translates to:
  /// **'Platforms country'**
  String get settingsWatchProvidersCountry;

  /// No description provided for @settingsWatchProvidersCountrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Region used for streaming offers'**
  String get settingsWatchProvidersCountrySubtitle;

  /// No description provided for @settingsWatchProvidersCountrySystem.
  ///
  /// In en, this message translates to:
  /// **'System ({country})'**
  String settingsWatchProvidersCountrySystem(String country);

  /// No description provided for @settingsAboutJustWatch.
  ///
  /// In en, this message translates to:
  /// **'Streaming data provided by JustWatch.'**
  String get settingsAboutJustWatch;

  /// No description provided for @personDirecting.
  ///
  /// In en, this message translates to:
  /// **'Directing / Creation'**
  String get personDirecting;

  /// No description provided for @personActing.
  ///
  /// In en, this message translates to:
  /// **'Acting'**
  String get personActing;

  /// No description provided for @personSeenCount.
  ///
  /// In en, this message translates to:
  /// **'{seen} of {total} seen'**
  String personSeenCount(int seen, int total);

  /// No description provided for @personOfflineNoData.
  ///
  /// In en, this message translates to:
  /// **'No cached information for this person.'**
  String get personOfflineNoData;

  /// No description provided for @sagaHeader.
  ///
  /// In en, this message translates to:
  /// **'Saga · {name}'**
  String sagaHeader(String name);

  /// No description provided for @sagaHeaderDefault.
  ///
  /// In en, this message translates to:
  /// **'Saga'**
  String get sagaHeaderDefault;

  /// No description provided for @sagaSeenCount.
  ///
  /// In en, this message translates to:
  /// **'{seen, plural, =0{0 of {total} films seen} =1{1 of {total} films seen} other{{seen} of {total} films seen}}'**
  String sagaSeenCount(int seen, int total);

  /// No description provided for @sagaCurrentItem.
  ///
  /// In en, this message translates to:
  /// **'This title'**
  String get sagaCurrentItem;

  /// No description provided for @sagaUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get sagaUpcoming;

  /// No description provided for @sagaUpcomingWithYear.
  ///
  /// In en, this message translates to:
  /// **'Upcoming ({year})'**
  String sagaUpcomingWithYear(String year);

  /// No description provided for @sagaAddMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 missing film to \"{list}\"} other{Add {count} missing films to \"{list}\"}}'**
  String sagaAddMissing(int count, String list);

  /// No description provided for @sagaMissingAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 film added to \"{list}\"} other{{count} films added to \"{list}\"}}'**
  String sagaMissingAdded(int count, String list);

  /// No description provided for @detailSeasonEpisodes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode} other{{count} episodes}}'**
  String detailSeasonEpisodes(int count);

  /// No description provided for @detailSeasonSeenShort.
  ///
  /// In en, this message translates to:
  /// **'{seen}/{total} seen'**
  String detailSeasonSeenShort(int seen, int total);

  /// No description provided for @togetherSessionSetup.
  ///
  /// In en, this message translates to:
  /// **'Session Setup'**
  String get togetherSessionSetup;

  /// No description provided for @togetherWeAreChoosing.
  ///
  /// In en, this message translates to:
  /// **'We are choosing'**
  String get togetherWeAreChoosing;

  /// No description provided for @togetherChoiceAny.
  ///
  /// In en, this message translates to:
  /// **'Movie or Series'**
  String get togetherChoiceAny;

  /// No description provided for @togetherChoiceMovie.
  ///
  /// In en, this message translates to:
  /// **'A Movie'**
  String get togetherChoiceMovie;

  /// No description provided for @togetherChoiceTv.
  ///
  /// In en, this message translates to:
  /// **'A Series'**
  String get togetherChoiceTv;

  /// No description provided for @togetherMyListLabel.
  ///
  /// In en, this message translates to:
  /// **'My list:'**
  String get togetherMyListLabel;

  /// No description provided for @togetherWarningNotice.
  ///
  /// In en, this message translates to:
  /// **'The QR code contains your list: anyone scanning it can view it.'**
  String get togetherWarningNotice;

  /// No description provided for @togetherScanQrButton.
  ///
  /// In en, this message translates to:
  /// **'Scan a friend\'s QR'**
  String get togetherScanQrButton;

  /// No description provided for @togetherParticipantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants'**
  String get togetherParticipantsTitle;

  /// No description provided for @togetherYouHost.
  ///
  /// In en, this message translates to:
  /// **'Me (Host)'**
  String get togetherYouHost;

  /// Name of a scanned participant whose QR code carries none; later ones get a number (Friend 2).
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get togetherFriendName;

  /// No description provided for @togetherItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 titles} =1{1 title} other{{count} titles}}'**
  String togetherItemsCount(int count);

  /// No description provided for @togetherScanPrompt.
  ///
  /// In en, this message translates to:
  /// **'Scan at least one friend to continue'**
  String get togetherScanPrompt;

  /// No description provided for @togetherSeeCommonTitles.
  ///
  /// In en, this message translates to:
  /// **'See common titles'**
  String get togetherSeeCommonTitles;

  /// No description provided for @togetherCommonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No titles in common} =1{1 title in common} other{{count} in common}}'**
  String togetherCommonCount(int count);

  /// No description provided for @togetherAlmostSection.
  ///
  /// In en, this message translates to:
  /// **'Almost: in {k} of {n} lists'**
  String togetherAlmostSection(int k, int n);

  /// No description provided for @togetherVoteLimitNotice.
  ///
  /// In en, this message translates to:
  /// **'Voting includes the 6 highest rated titles (out of {count})'**
  String togetherVoteLimitNotice(int count);

  /// No description provided for @togetherEmptyCommonTitle.
  ///
  /// In en, this message translates to:
  /// **'No titles in common'**
  String get togetherEmptyCommonTitle;

  /// No description provided for @togetherEmptyCommonMessage.
  ///
  /// In en, this message translates to:
  /// **'None of your titles match across all lists. Check the \"Almost\" section below!'**
  String get togetherEmptyCommonMessage;

  /// No description provided for @togetherRandomPick.
  ///
  /// In en, this message translates to:
  /// **'Random pick'**
  String get togetherRandomPick;

  /// No description provided for @togetherSwipeVote.
  ///
  /// In en, this message translates to:
  /// **'Vote by swiping'**
  String get togetherSwipeVote;

  /// No description provided for @togetherWatchThis.
  ///
  /// In en, this message translates to:
  /// **'Let\'s watch this!'**
  String get togetherWatchThis;

  /// No description provided for @togetherResetSession.
  ///
  /// In en, this message translates to:
  /// **'Reset session'**
  String get togetherResetSession;

  /// No description provided for @togetherResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset this session and clear all scanned participants?'**
  String get togetherResetConfirm;

  /// No description provided for @togetherHideSeen.
  ///
  /// In en, this message translates to:
  /// **'Hide watched'**
  String get togetherHideSeen;

  /// No description provided for @togetherMultiQrPart.
  ///
  /// In en, this message translates to:
  /// **'Part {current} of {total}'**
  String togetherMultiQrPart(int current, int total);

  /// No description provided for @togetherScanNextPart.
  ///
  /// In en, this message translates to:
  /// **'Scan next QR part ({current}/{total})'**
  String togetherScanNextPart(int current, int total);

  /// No description provided for @togetherLeaveVoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave voting'**
  String get togetherLeaveVoteTitle;

  /// No description provided for @togetherLeaveVoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Votes already cast will be lost. Participants will remain in the session.'**
  String get togetherLeaveVoteConfirm;

  /// No description provided for @togetherLeaveVoteButton.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get togetherLeaveVoteButton;

  /// No description provided for @togetherYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn to vote'**
  String get togetherYourTurn;

  /// No description provided for @togetherHostStartVote.
  ///
  /// In en, this message translates to:
  /// **'I\'m voting'**
  String get togetherHostStartVote;

  /// No description provided for @togetherPassPhone.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone to {name}'**
  String togetherPassPhone(String name);

  /// No description provided for @togetherParticipantStartVote.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get togetherParticipantStartVote;

  /// No description provided for @togetherVoteProgress.
  ///
  /// In en, this message translates to:
  /// **'Title {current} of {total}'**
  String togetherVoteProgress(int current, int total);

  /// No description provided for @togetherVoteYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get togetherVoteYes;

  /// No description provided for @togetherVoteNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get togetherVoteNo;

  /// No description provided for @togetherTonightChoice.
  ///
  /// In en, this message translates to:
  /// **'Tonight\'s choice'**
  String get togetherTonightChoice;

  /// No description provided for @togetherUnanimousVote.
  ///
  /// In en, this message translates to:
  /// **'Unanimous!'**
  String get togetherUnanimousVote;

  /// No description provided for @togetherVoteCountFraction.
  ///
  /// In en, this message translates to:
  /// **'{count} votes out of {total}'**
  String togetherVoteCountFraction(int count, int total);

  /// No description provided for @togetherTieBadge.
  ///
  /// In en, this message translates to:
  /// **'Tie'**
  String get togetherTieBadge;

  /// No description provided for @togetherOtherTitles.
  ///
  /// In en, this message translates to:
  /// **'Other titles'**
  String get togetherOtherTitles;

  /// No description provided for @togetherReviewList.
  ///
  /// In en, this message translates to:
  /// **'Review list'**
  String get togetherReviewList;

  /// No description provided for @togetherWatchingToast.
  ///
  /// In en, this message translates to:
  /// **'Enjoy watching {title}!'**
  String togetherWatchingToast(String title);

  /// No description provided for @swiperDiscardedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No discarded titles} =1{1 discarded title} other{{count} discarded titles}}'**
  String swiperDiscardedCount(int count);

  /// No description provided for @swiperResetButton.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get swiperResetButton;

  /// No description provided for @swiperResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset swipe choices?'**
  String get swiperResetConfirmTitle;

  /// No description provided for @swiperResetConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Titles you previously discarded will be able to appear again in swipe mode. Your earned achievements remain unlocked.'**
  String get swiperResetConfirmMessage;

  /// No description provided for @swiperResetSuccessToast.
  ///
  /// In en, this message translates to:
  /// **'Swipe choices reset'**
  String get swiperResetSuccessToast;

  /// No description provided for @settingsAboutTmdb.
  ///
  /// In en, this message translates to:
  /// **'This product uses the TMDB API but is not endorsed or certified by TMDB.'**
  String get settingsAboutTmdb;
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
