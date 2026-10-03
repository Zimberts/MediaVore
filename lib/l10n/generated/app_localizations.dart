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
  /// **'Refetch Media Runtimes'**
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
  /// **'This file contains:\nSeen: {seen}\nLikes: {likes}\nNotifications: {notifications}\nLists: {lists}\n\nChoose how to apply the data to your current profile.'**
  String dataImportPreviewMessage(
    int seen,
    int likes,
    int notifications,
    int lists,
  );

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

  /// No description provided for @listsGridSize.
  ///
  /// In en, this message translates to:
  /// **'Grid Size'**
  String get listsGridSize;

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

  /// No description provided for @listsShowQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code'**
  String get listsShowQr;

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

  /// No description provided for @listsCouldNotParseLink.
  ///
  /// In en, this message translates to:
  /// **'Could not parse link'**
  String get listsCouldNotParseLink;

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

  /// No description provided for @listsRemoveSelected.
  ///
  /// In en, this message translates to:
  /// **'Remove selected'**
  String get listsRemoveSelected;

  /// No description provided for @listsDisplayMode.
  ///
  /// In en, this message translates to:
  /// **'Display Mode'**
  String get listsDisplayMode;

  /// No description provided for @listsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items in this list.'**
  String get listsEmpty;

  /// No description provided for @listsSwitchList.
  ///
  /// In en, this message translates to:
  /// **'Switch List'**
  String get listsSwitchList;

  /// No description provided for @listsItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String listsItemCount(int count);

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

  /// No description provided for @mediaSeasonShort.
  ///
  /// In en, this message translates to:
  /// **'{count} S'**
  String mediaSeasonShort(String count);

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

  /// No description provided for @seenFilterSort.
  ///
  /// In en, this message translates to:
  /// **'Filter & Sort'**
  String get seenFilterSort;

  /// No description provided for @seenViewMode.
  ///
  /// In en, this message translates to:
  /// **'View Mode'**
  String get seenViewMode;

  /// No description provided for @seenViewHistory.
  ///
  /// In en, this message translates to:
  /// **'History (All episodes)'**
  String get seenViewHistory;

  /// No description provided for @seenViewLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library (Unique titles)'**
  String get seenViewLibrary;

  /// No description provided for @seenSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get seenSortBy;

  /// No description provided for @seenSortDateNewest.
  ///
  /// In en, this message translates to:
  /// **'Date (Newest)'**
  String get seenSortDateNewest;

  /// No description provided for @seenSortDateOldest.
  ///
  /// In en, this message translates to:
  /// **'Date (Oldest)'**
  String get seenSortDateOldest;

  /// No description provided for @seenSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get seenSortNameAsc;

  /// No description provided for @seenSortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get seenSortNameDesc;

  /// No description provided for @seenMediaType.
  ///
  /// In en, this message translates to:
  /// **'Media Type'**
  String get seenMediaType;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

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
  /// **'Seen History'**
  String get seenTitle;

  /// No description provided for @seenSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search history...'**
  String get seenSearchHint;

  /// No description provided for @seenStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get seenStatistics;

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

  /// No description provided for @seenNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found.'**
  String get seenNoMatches;

  /// No description provided for @seenEpisodesSeen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode seen} other{{count} episodes seen}}'**
  String seenEpisodesSeen(int count);

  /// No description provided for @seenCannotDeleteLibrary.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete from Library mode. Switch to History to remove entries.'**
  String get seenCannotDeleteLibrary;

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

  /// No description provided for @statsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsOverview;

  /// No description provided for @statsDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get statsDistribution;

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

  /// No description provided for @statsEpisodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get statsEpisodes;

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

  /// No description provided for @statsPieLabel.
  ///
  /// In en, this message translates to:
  /// **'{type}\n{percent}%'**
  String statsPieLabel(String type, String percent);

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

  /// No description provided for @discoveryReleaseYear.
  ///
  /// In en, this message translates to:
  /// **'Release Year'**
  String get discoveryReleaseYear;

  /// No description provided for @discoveryAnyYear.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get discoveryAnyYear;

  /// No description provided for @discoveryMinRating.
  ///
  /// In en, this message translates to:
  /// **'Min Rating: {rating}'**
  String discoveryMinRating(String rating);

  /// No description provided for @discoveryGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get discoveryGenres;

  /// No description provided for @discoveryReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get discoveryReset;

  /// No description provided for @discoveryApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get discoveryApply;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @discoverySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search within Discovery...'**
  String get discoverySearchHint;

  /// No description provided for @discoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoveryTitle;

  /// No description provided for @discoveryNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get discoveryNoResults;

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

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get notifTitle;

  /// No description provided for @notifForceRefresh.
  ///
  /// In en, this message translates to:
  /// **'Force Refresh'**
  String get notifForceRefresh;

  /// No description provided for @notifTabReleases.
  ///
  /// In en, this message translates to:
  /// **'Releases'**
  String get notifTabReleases;

  /// No description provided for @notifTabQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get notifTabQuickAdd;

  /// No description provided for @notifSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing releases...'**
  String get notifSyncing;

  /// No description provided for @notifNoReleases.
  ///
  /// In en, this message translates to:
  /// **'No upcoming or recent releases.'**
  String get notifNoReleases;

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

  /// No description provided for @notifMarkedAsSeen.
  ///
  /// In en, this message translates to:
  /// **'Marked {title} as seen'**
  String notifMarkedAsSeen(String title);

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

  /// No description provided for @notifNextEpisode.
  ///
  /// In en, this message translates to:
  /// **'Next: Season {season}, Episode {episode}'**
  String notifNextEpisode(int season, int episode);

  /// No description provided for @notifStreakOptedOut.
  ///
  /// In en, this message translates to:
  /// **'Streak opted out of Quick Add'**
  String get notifStreakOptedOut;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @notifEpisode.
  ///
  /// In en, this message translates to:
  /// **'episode'**
  String get notifEpisode;

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

  /// No description provided for @detailCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get detailCreator;

  /// No description provided for @detailDirector.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get detailDirector;

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

  /// No description provided for @detailCreditLine.
  ///
  /// In en, this message translates to:
  /// **'{role}: {name}'**
  String detailCreditLine(String role, String name);

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

  /// No description provided for @detailWatchOn.
  ///
  /// In en, this message translates to:
  /// **'Watch on:'**
  String get detailWatchOn;

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

  /// No description provided for @seenOpenHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get seenOpenHistory;

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

  /// No description provided for @seenViewingHistory.
  ///
  /// In en, this message translates to:
  /// **'Viewing History'**
  String get seenViewingHistory;

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
  /// **'Date (DD/MM/YYYY)'**
  String get seenDateLabel;

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
  /// **'Please enter a valid date (DD/MM/YYYY)'**
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

  /// No description provided for @progressRefetchDone.
  ///
  /// In en, this message translates to:
  /// **'Done refetching data!'**
  String get progressRefetchDone;

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
