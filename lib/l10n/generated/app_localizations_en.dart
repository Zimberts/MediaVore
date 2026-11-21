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
  String get appStartupFailedTitle => 'MediaVore could not start';

  @override
  String get appStartupFailedMessage =>
      'Something went wrong while loading your data. Please try again.';

  @override
  String get appStartupTechnicalDetails => 'Technical details';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonImport => 'Import';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navHistory => 'History';

  @override
  String get emptyStateSearchAction => 'Search a movie or series';

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
  String get tmdbOnboardingTitle => 'Connect to TMDB';

  @override
  String get tmdbOnboardingWhy =>
      'MediaVore gets movie and series data (posters, synopses, release dates) from The Movie Database (TMDB). TMDB asks each user for a free personal key.';

  @override
  String get tmdbOnboardingStepGetKey =>
      '1. Create a free TMDB account, then open its API settings page.';

  @override
  String get tmdbOnboardingOpenTmdb => 'Open the TMDB API page';

  @override
  String get tmdbOnboardingStepPaste =>
      '2. Copy the \"API Read Access Token\" (or the \"API Key\") and paste it below.';

  @override
  String tmdbCredentialLinkCopied(String url) {
    return 'Couldn\'t open the browser. Link copied: $url';
  }

  @override
  String get tmdbCredentialHint => 'Enter TMDB v3 API key or v4 read token';

  @override
  String get tmdbCredentialPaste => 'Paste';

  @override
  String get tmdbCredentialShow => 'Show';

  @override
  String get tmdbCredentialHide => 'Hide';

  @override
  String get tmdbCredentialVerifyAndSave => 'Verify and save';

  @override
  String get tmdbCredentialVerifying => 'Checking with TMDB…';

  @override
  String get tmdbCredentialSaved => 'TMDB key verified and saved.';

  @override
  String get tmdbCredentialInvalid =>
      'TMDB rejected this key. Check that you copied the whole API key or read access token.';

  @override
  String tmdbCredentialCheckFailed(String reason) {
    return 'The key could not be verified: $reason';
  }

  @override
  String get tmdbCredentialSaveAnyway => 'Save without verifying';

  @override
  String get tmdbCredentialRemove => 'Remove key';

  @override
  String get tmdbCredentialLater =>
      'You can set your API key later in Me › TMDB API Credential.';

  @override
  String get tmdbCredentialSkip => 'Skip for now';

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
  String get paletteNamePaper => 'Paper';

  @override
  String get paletteNameSand => 'Sand';

  @override
  String get paletteNameMist => 'Mist';

  @override
  String get paletteNameInk => 'Ink';

  @override
  String get paletteNameNight => 'Night';

  @override
  String get paletteNameOled => 'OLED black';

  @override
  String get paletteNameClassicLight => 'Classic Light';

  @override
  String get paletteNameParchment => 'Parchment';

  @override
  String get paletteNameMint => 'Mint';

  @override
  String get paletteNameSolarizedLight => 'Solarized Light';

  @override
  String get paletteNamePinky => 'Pinky';

  @override
  String get paletteNameClassicDark => 'Classic Dark';

  @override
  String get paletteNameSlate => 'Slate';

  @override
  String get paletteNameMidnight => 'Midnight';

  @override
  String get paletteNameEspresso => 'Espresso';

  @override
  String get profileTitle => 'Me';

  @override
  String get profileAchievements => 'Achievements';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileSettingsSubtitle => 'Appearance, display and preferences.';

  @override
  String get settingsHideNonReleased => 'Hide Non-Released Media';

  @override
  String get settingsHideNonReleasedSubtitle =>
      'Only show movies and episodes that have already aired.';

  @override
  String get settingsStorage => 'Storage & Data';

  @override
  String get settingsStorageSubtitle =>
      'Manage cache, exports, and viewing history database.';

  @override
  String get settingsTmdbCredential => 'TMDB API Credential';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsAboutDescription =>
      'A simple media tracking app using TMDB.';

  @override
  String get dataSectionCache => 'Cache Management';

  @override
  String get dataCacheSize => 'Cache Size';

  @override
  String get dataCleanupCache => 'Cleanup Cache';

  @override
  String get dataCleanupCacheSubtitle =>
      'Remove old, unused search results and details.';

  @override
  String get dataCleanupCacheMessage =>
      'This will remove search results and details older than 60 days that are not in your lists.';

  @override
  String get dataFillCache => 'Fill Cache';

  @override
  String get dataFillCacheSubtitle =>
      'Pre-cache all items in your lists and recent history for offline use.';

  @override
  String dataCachingTitles(int done, int total) {
    return 'Caching titles: $done / $total';
  }

  @override
  String get dataWipeCache => 'Wipe All Cache';

  @override
  String get dataWipeCacheSubtitle => 'Delete everything from cache.';

  @override
  String get dataWipeCacheMessage =>
      'This will delete ALL cached posters and details. You will need internet to see them again.';

  @override
  String get dataSectionData => 'Data Management';

  @override
  String get dataSeenDbSize => 'Seen Database Size';

  @override
  String get dataRefetchRuntimes => 'Refetch missing data';

  @override
  String get dataRefetchRuntimesSubtitle =>
      'Fetch missing runtimes and genres for your history.';

  @override
  String get dataRefetchTitle => 'Refetch Data';

  @override
  String get dataRefetchMessage =>
      'This will check your seen history and fetch any missing runtimes or genres from TMDb. This might take a while.';

  @override
  String get dataExportAll => 'Export All Data';

  @override
  String get dataExportAllSubtitle =>
      'Export seen, likes, notifications and lists as a single MDV file.';

  @override
  String get dataSaveToDevice => 'Save to device';

  @override
  String get dataShareViaSystem => 'Share via System';

  @override
  String get dataExportShareText => 'MediaVore Export';

  @override
  String get dataImportAll => 'Import All Data';

  @override
  String get dataImportAllSubtitle =>
      'Import seen, likes, notifications and lists from an export MDV or ZIP.';

  @override
  String get dataPopulateQuickAdd => 'Populate Quick Add from Seen History';

  @override
  String get dataPopulateQuickAddSubtitle =>
      'Compute next episodes from your seen history and save them to Quick Add.';

  @override
  String get dataPopulateQuickAddTitle => 'Populate Quick Add';

  @override
  String get dataPopulateQuickAddMessage =>
      'This will compute next unseen episodes for your TV shows and add them to Quick Add. Proceed?';

  @override
  String get dataPopulateQuickAddDone => 'Quick Add populated from history.';

  @override
  String get dataSectionAchievements => 'Achievement Data';

  @override
  String get dataClearAchievements => 'Clear Achievement Database';

  @override
  String get dataClearAchievementsSubtitle =>
      'Remove all persisted achievement milestones.';

  @override
  String get dataClearAchievementsTitle => 'Clear Achievements?';

  @override
  String get dataClearAchievementsMessage =>
      'This will remove all persisted achievement dates from the database. Achievements calculated from your watch history will reappear automatically.';

  @override
  String get dataClearAchievementsDone => 'Achievement database cleared.';

  @override
  String get dataSectionDebug => 'Debug';

  @override
  String get dataNotificationDebug => 'Notification Center Debug';

  @override
  String get dataNotificationDebugSubtitle =>
      'Show hidden Notification Center items and why they were omitted.';

  @override
  String get commonProcessing => 'Processing...';

  @override
  String get dataExporting => 'Exporting data...';

  @override
  String get dataReadingBackup => 'Reading backup...';

  @override
  String get dataSaveExportDialog => 'Save Export';

  @override
  String get dataFileSaved => 'File saved successfully';

  @override
  String dataSaveFailed(String error) {
    return 'Save failed: $error. Try using \"Share\" instead.';
  }

  @override
  String get dataInvalidFile =>
      'Please select a valid .mdv or .zip export file.';

  @override
  String get dataImportPreviewTitle => 'Import Preview';

  @override
  String dataImportPreviewMessage(
    int seen,
    int likes,
    int notifications,
    int lists,
    String warnings,
  ) {
    return 'This file contains:\nSeen: $seen\nLikes: $likes\nNotifications: $notifications\nLists: $lists\n$warnings\nChoose how to apply the data to your current profile.';
  }

  @override
  String dataImportSkippedRows(int count) {
    return '$count invalid row(s) will be skipped:';
  }

  @override
  String get dataImportedAppended => 'Imported (Appended)';

  @override
  String get dataAppend => 'Append';

  @override
  String get dataImportedMerged => 'Imported (Merged)';

  @override
  String get dataMerge => 'Merge';

  @override
  String get dataImportedReplaced => 'Imported (Replaced)';

  @override
  String get dataReplace => 'Replace';

  @override
  String get dataImportFailed => 'Import failed: Invalid file format';

  @override
  String dataImportFailedReason(String reason) {
    return 'Import failed: $reason';
  }

  @override
  String get dataReplaceTitle => 'DANGER: Replace History';

  @override
  String get dataReplaceMessage =>
      'This will delete all your current seen history and replace it with the data from the file. This action cannot be undone. Are you absolutely sure?';

  @override
  String get dataReplaceConfirm => 'Yes, Replace Everything';

  @override
  String get commonProceed => 'Proceed';

  @override
  String get listsDisplayOptions => 'Display Options';

  @override
  String get listsSharingImporting => 'Sharing & Importing';

  @override
  String get listsScanQr => 'Scan QR Code';

  @override
  String get listsImportViaLink => 'Import via Link';

  @override
  String get listsShareWebLink => 'Share Web Link (WhatsApp/SMS)';

  @override
  String listsShareLinkMessage(String list, String link) {
    return 'Check out my $list on MediaVore: $link';
  }

  @override
  String listsQrShareMessage(String list) {
    return 'Scan this QR code to import my $list on MediaVore';
  }

  @override
  String listsQrShareError(String error) {
    return 'Error sharing QR code: $error';
  }

  @override
  String listsShareTitle(String list) {
    return 'Share $list';
  }

  @override
  String get listsQrCaption => 'MediaVore List Share';

  @override
  String get listsQrHint => 'Scan this with another phone to import the list.';

  @override
  String get listsShareQrImage => 'Share QR Code Image';

  @override
  String get commonClose => 'Close';

  @override
  String get listsScanTitle => 'Scan MediaVore List';

  @override
  String get listsScanHint => 'Point your camera at a MediaVore QR code';

  @override
  String get listsPasteLinkHint => 'Paste the shared link here';

  @override
  String get listsShareLinkLabel => 'Share Link';

  @override
  String get listsInvalidLink => 'Invalid link format';

  @override
  String get listsConfirmImport => 'Confirm Import';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get listsSortOptions => 'Sort Options';

  @override
  String get listsMoreActions => 'More actions';

  @override
  String get listsSortManual => 'Manual Order';

  @override
  String get listsSortManualHint => 'Drag and drop items to reorder';

  @override
  String get listsSortReleaseDate => 'Release Date';

  @override
  String get listsSortReleaseDateHint => 'Sort by when it was released';

  @override
  String get listsSortShuffle => 'Shuffle';

  @override
  String get listsSortShuffleHint => 'Randomize the list';

  @override
  String get listsReverseOrder => 'Reverse Order';

  @override
  String listsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get listsWatchlist => 'Watchlist';

  @override
  String get listsEmpty => 'No items in this list.';

  @override
  String get listsCreateNew => 'Create New List';

  @override
  String get listsNewList => 'New List';

  @override
  String get listsNameHint => 'List name';

  @override
  String get commonCreate => 'Create';

  @override
  String get listsDeleteList => 'Delete List';

  @override
  String listsDeleteListMessage(String list) {
    return 'Are you sure you want to delete \"$list\"? This will also remove all items from this list.';
  }

  @override
  String get commonDelete => 'Delete';

  @override
  String mediaSeasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seasons',
      one: '1 season',
    );
    return '$_temp0';
  }

  @override
  String mediaRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get seenRemoveLogTitle => 'Remove log?';

  @override
  String get seenRemoveLogMessage =>
      'Are you sure you want to remove this viewing entry from your history?';

  @override
  String get commonRemove => 'Remove';

  @override
  String get seenSortBy => 'Sort by';

  @override
  String get seenMediaType => 'Media Type';

  @override
  String get commonMovies => 'Movies';

  @override
  String get commonTvShows => 'TV Shows';

  @override
  String get seenTitle => 'History';

  @override
  String get seenSearchHint => 'Search history...';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get seenEmpty => 'No items seen yet.';

  @override
  String get seenEmptyHint =>
      'Mark a movie or an episode as seen to start your history.';

  @override
  String get seenNoMatches => 'No matches found.';

  @override
  String get statsTitle => 'Media Stats';

  @override
  String get statsEmpty => 'No data yet. Start watching!';

  @override
  String get statsToggleMetric => 'Toggle Metric (Logs/Time)';

  @override
  String get statsAllTime => 'All Time';

  @override
  String get statsYear => 'Year';

  @override
  String get statsMonth => 'Month';

  @override
  String get statsSelectYear => 'Select Year';

  @override
  String get statsSelectPeriod => 'Select Period';

  @override
  String get statsPreviousPeriod => 'Previous period';

  @override
  String get statsNextPeriod => 'Next period';

  @override
  String get statsTotalWatchTime => 'Total Watch Time';

  @override
  String statsDuration(int days, int hours, int minutes) {
    return '${days}d ${hours}h ${minutes}m';
  }

  @override
  String statsHallOfFame(String metric) {
    return 'Hall of Fame ($metric)';
  }

  @override
  String get statsMostWatchedMovie => 'Most Watched Movie';

  @override
  String get statsMostWatchedSeries => 'Most Watched Series';

  @override
  String get statsMostWatchedEpisode => 'Most Watched Episode';

  @override
  String get statsActivityLogs => 'Viewing Activity (logs)';

  @override
  String get statsActivityMinutes => 'Viewing Activity (minutes)';

  @override
  String statsLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '1 log',
    );
    return '$_temp0';
  }

  @override
  String statsHours(String hours) {
    return '${hours}h';
  }

  @override
  String get statsNoActivity => 'No activity data';

  @override
  String statsTooltip(String label, int value, String unit) {
    return '$label\n$value $unit';
  }

  @override
  String statsMediaSplit(String metric) {
    return 'Media Split ($metric)';
  }

  @override
  String statsTopGenres(String metric) {
    return 'Top Genres (by $metric)';
  }

  @override
  String statsGenreValue(String value, String percent) {
    return '$value ($percent%)';
  }

  @override
  String get statsMetricLogs => 'logs';

  @override
  String get statsMetricTime => 'time';

  @override
  String get statsNoDataForPeriod => 'No viewing data for this period';

  @override
  String get statsDecades => 'By release decade';

  @override
  String get statsDecadeBefore1990 => 'Before 1990';

  @override
  String get statsDecadeAfter2020 => '2020 and later';

  @override
  String statsAverageRating(String rating) {
    return '$rating ★';
  }

  @override
  String get statsSeriesProgression => 'Series';

  @override
  String statsSeriesProgressCount(int watched, int total, String percent) {
    return '$watched / $total episodes ($percent%)';
  }

  @override
  String statsSeriesWatchedEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String get statsListsAndDiscovery => 'Lists and discovery';

  @override
  String statsWatchlistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles in Watchlist',
      one: '1 title in Watchlist',
    );
    return '$_temp0';
  }

  @override
  String statsCustomListsCount(int listsCount, int itemsCount) {
    String _temp0 = intl.Intl.pluralLogic(
      listsCount,
      locale: localeName,
      other: '$listsCount custom lists',
      one: '1 custom list',
    );
    return '$_temp0 ($itemsCount titles)';
  }

  @override
  String get statsFooterDatedHistory => 'Calculated on dated viewing history.';

  @override
  String statsMoviesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count movies',
      one: '1 movie',
    );
    return '$_temp0';
  }

  @override
  String statsEpisodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String get genreAction => 'Action';

  @override
  String get genreAdventure => 'Adventure';

  @override
  String get genreAnimation => 'Animation';

  @override
  String get genreComedy => 'Comedy';

  @override
  String get genreCrime => 'Crime';

  @override
  String get genreDocumentary => 'Documentary';

  @override
  String get genreDrama => 'Drama';

  @override
  String get genreFamily => 'Family';

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreHistory => 'History';

  @override
  String get genreHorror => 'Horror';

  @override
  String get genreMusic => 'Music';

  @override
  String get genreMystery => 'Mystery';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreSciFi => 'Sci-Fi';

  @override
  String get genreTvMovie => 'TV Movie';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreWar => 'War';

  @override
  String get genreWestern => 'Western';

  @override
  String get genreActionAdventure => 'Action & Adventure';

  @override
  String get genreKids => 'Kids';

  @override
  String get genreNews => 'News';

  @override
  String get genreReality => 'Reality';

  @override
  String get genreSciFiFantasy => 'Sci-Fi & Fantasy';

  @override
  String get genreSoap => 'Soap';

  @override
  String get genreTalk => 'Talk';

  @override
  String get genreWarPolitics => 'War & Politics';

  @override
  String get discoveryFiltersTitle => 'Discovery Filters';

  @override
  String get discoveryBoth => 'Both';

  @override
  String get discoveryGenres => 'Genres';

  @override
  String get commonRetry => 'Retry';

  @override
  String get discoveryTitle => 'Discover';

  @override
  String get discoveryClearFilters => 'Clear Filters';

  @override
  String get releaseEpisodeTba => 'Episode — date TBA';

  @override
  String get releaseReturning => 'Returning — new season planned';

  @override
  String get releasePlanned => 'Planned — no release date';

  @override
  String get notifNoReleases => 'No upcoming or recent releases.';

  @override
  String get notifNoReleasesHint =>
      'Movies and series on your watchlist or with alerts on show their releases here.';

  @override
  String notifReleaseDate(String released, String date) {
    String _temp0 = intl.Intl.selectLogic(released, {
      'true': 'Released',
      'other': 'Releases',
    });
    return '$_temp0: $date';
  }

  @override
  String get commonMarkAsSeen => 'Mark as seen';

  @override
  String get notifNoNextEpisodes => 'No next episodes to track.';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonUndo => 'Undo';

  @override
  String get detailOfflineSeason => 'Cannot load season details while offline.';

  @override
  String get detailNoHistoryToExport => 'No history to export for this item.';

  @override
  String detailHistoryShareText(String title) {
    return 'Seen history for $title';
  }

  @override
  String get detailSaveHistoryDialog => 'Save History';

  @override
  String detailSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get detailExportHistory => 'Export history for this item';

  @override
  String detailProgress(int seen, int total) {
    return 'Progress: $seen / $total episodes seen';
  }

  @override
  String get detailOfflineMode => 'Offline Mode';

  @override
  String get detailOfflineMessage =>
      'Detailed information is unavailable without internet.';

  @override
  String get commonTryAgain => 'Try Again';

  @override
  String detailSeasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seasons',
      one: '1 Season',
    );
    return '$_temp0';
  }

  @override
  String detailEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Episodes',
      one: '1 Episode',
    );
    return '$_temp0';
  }

  @override
  String get detailOverview => 'Overview';

  @override
  String get detailSeasons => 'Seasons';

  @override
  String detailSeasonName(int number) {
    return 'Season $number';
  }

  @override
  String detailSeasonProgress(int seen, int total) {
    return '$seen / $total episodes seen';
  }

  @override
  String get detailCast => 'Cast';

  @override
  String get detailSimilar => 'Similar';

  @override
  String get detailRecommendations => 'Recommendations';

  @override
  String get detailTrailers => 'Trailers';

  @override
  String get statusReleased => 'Released';

  @override
  String get statusReturning => 'Returning Series';

  @override
  String get statusEnded => 'Ended';

  @override
  String get statusCanceled => 'Canceled';

  @override
  String get statusInProduction => 'In Production';

  @override
  String get statusPostProduction => 'Post Production';

  @override
  String get statusPlanned => 'Planned';

  @override
  String get statusRumored => 'Rumored';

  @override
  String get statusPilot => 'Pilot';

  @override
  String get seenEpisodesSeenTitle => 'Episodes Seen';

  @override
  String get seenSeen => 'Seen';

  @override
  String seenEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get seenClearHistory => 'Clear History';

  @override
  String seenClearHistoryMessage(String title) {
    return 'Are you sure you want to clear all viewing history for \"$title\"?';
  }

  @override
  String get seenClearAll => 'Clear All';

  @override
  String get seenAddViewing => 'Add New Viewing';

  @override
  String get seenNoHistory => 'No viewing history found for this item.';

  @override
  String get seenRemoveAllHistory => 'Remove All History';

  @override
  String get seenUseCalendar => 'Use Calendar';

  @override
  String get seenTypeDate => 'Type Date';

  @override
  String get seenDateLabel => 'Date (MM/DD/YYYY)';

  @override
  String get seenDateHint => '12/31/2023';

  @override
  String seenTimeLabel(String time) {
    return 'Time: $time';
  }

  @override
  String get seenCancelCaps => 'CANCEL';

  @override
  String get seenInvalidDate => 'Please enter a valid date (MM/DD/YYYY)';

  @override
  String get seenLogViewing => 'LOG VIEWING';

  @override
  String get likeUnlike => 'Unlike';

  @override
  String get likeLike => 'Like';

  @override
  String get notifyDisable => 'Disable notifications';

  @override
  String get notifyEnable => 'Notify me on release';

  @override
  String get watchlistRemove => 'Remove from watchlist';

  @override
  String get watchlistAdd => 'Add to watchlist';

  @override
  String watchNext(int season, int episode) {
    return 'Watch Next: S$season E$episode';
  }

  @override
  String actorLoadFailed(String error) {
    return 'Failed to load actor details: $error';
  }

  @override
  String get actorBiography => 'Biography';

  @override
  String get actorKnownFor => 'Known For';

  @override
  String get achievementsOverall => 'Overall Progress';

  @override
  String get achievementsCategoryMovies => 'Movies';

  @override
  String get achievementsCategoryTv => 'Series';

  @override
  String get achievementsCategoryBooks => 'Books';

  @override
  String get achievementsCategoryDiscovery => 'Discovery';

  @override
  String get achievementsCategoryTogether => 'Together';

  @override
  String get achievementsCategoryRegularity => 'Regularity';

  @override
  String achievementsUnlockedCount(int unlocked, int total) {
    return 'You\'ve unlocked $unlocked out of $total badges';
  }

  @override
  String achievementsUnlockedOn(String date) {
    return 'Unlocked on $date';
  }

  @override
  String achievementsChallengesCompleted(int completed, int total) {
    return '$completed / $total challenges completed';
  }

  @override
  String achievementsLevelProgress(int unlocked, int total) {
    return 'Level $unlocked/$total';
  }

  @override
  String achievementsLevelTitle(int level, String title) {
    return 'Level $level · $title';
  }

  @override
  String achievementsNextLevel(String title, String progress) {
    return 'Next: $title · $progress';
  }

  @override
  String get achievementsAllLevelsCompleted => 'All levels completed';

  @override
  String achievementLevelUnlocked(int level) {
    return 'Level $level Unlocked!';
  }

  @override
  String get progressImportingAll => 'Importing all data...';

  @override
  String get progressDone => 'Done!';

  @override
  String progressError(String error) {
    return 'Error: $error';
  }

  @override
  String get progressRefetchingRuntimes => 'Refetching missing runtimes...';

  @override
  String progressRefetchingItem(String title) {
    return 'Refetching $title...';
  }

  @override
  String progressProcessingItem(String title) {
    return 'Processing $title...';
  }

  @override
  String get progressSavingEntries => 'Saving entries...';

  @override
  String get progressImportComplete => 'Import complete';

  @override
  String get mediaKindMovie => 'Movie';

  @override
  String get mediaKindSeries => 'Series';

  @override
  String get mediaKindBook => 'Book';

  @override
  String get swiperTitle => 'Swiper';

  @override
  String get swiperAddTo => 'Add to';

  @override
  String get swiperDiscard => 'Discard';

  @override
  String get swiperAdd => 'Add';

  @override
  String get swiperUndo => 'Undo';

  @override
  String get swiperEmptyTitle => 'No more movies';

  @override
  String get swiperEmptyMessage =>
      'You\'ve gone through all available movies for now.';

  @override
  String swiperSessionStats(int added, int discarded) {
    return '$added added · $discarded discarded';
  }

  @override
  String get swiperSettingTitle => 'Swipe mode in Discover';

  @override
  String get swiperSettingSubtitle =>
      'Show swipe mode to discover movies card by card';

  @override
  String swiperSagaBadge(int count) {
    return 'Saga ($count movies)';
  }

  @override
  String get commonSeeAll => 'See all';

  @override
  String get offlineBannerTitle => 'Offline';

  @override
  String get posterInProgress => 'In progress';

  @override
  String get posterLiked => 'Liked';

  @override
  String posterRating(String rating) {
    return 'Rated $rating';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navTogether => 'Together';

  @override
  String get navMe => 'Me';

  @override
  String get librarySectionLists => 'Lists';

  @override
  String get homeTitle => 'Tonight';

  @override
  String get homeOfflineMessage =>
      'releases will be refreshed when the network is back.';

  @override
  String get homeResume => 'Resume';

  @override
  String homeEpisodeCode(int season, int episode) {
    return 'S$season E$episode';
  }

  @override
  String homeNextEpisode(String episode) {
    return 'Next: $episode';
  }

  @override
  String homeMarkEpisodeSeen(String episode, String title) {
    return 'Mark $episode of $title as seen';
  }

  @override
  String homeEpisodeSeenMessage(String episode, String title) {
    return '$episode seen · $title';
  }

  @override
  String get homeTonightTitle => 'To watch tonight';

  @override
  String get homeTonightOtherIdea => 'Another idea';

  @override
  String homeTonightSource(String list, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles not seen yet',
      one: '1 title not seen yet',
    );
    return 'From your list \"$list\" · $_temp0';
  }

  @override
  String get homeChooseTogether => 'Choose together';

  @override
  String get homeChooseTogetherSubtitle => 'Compare your lists and vote';

  @override
  String get homeEmptyTitle => 'Nothing planned tonight.';

  @override
  String homeEmptyMessage(String list) {
    return 'Add films or series to your list \"$list\" to find them here.';
  }

  @override
  String get homeEmptyAction => 'Discover titles';

  @override
  String homeAlsoInProgress(int count) {
    return 'Also in progress · $count';
  }

  @override
  String homeSeeAllCount(int count) {
    return 'See all ($count)';
  }

  @override
  String get homeRecentAreInResume => 'The most recent ones are in \"Resume\".';

  @override
  String homeFilterAll(int count) {
    return 'All · $count';
  }

  @override
  String homeFilterSeries(int count) {
    return 'Series · $count';
  }

  @override
  String homeFilterBooks(int count) {
    return 'Books · $count';
  }

  @override
  String homeMoreInProgress(int count) {
    return '$count more, see all';
  }

  @override
  String homePausedTitle(int count) {
    return '$count paused';
  }

  @override
  String homePausedSubtitle(int days) {
    return 'No activity for more than $days days';
  }

  @override
  String get homeAgoToday => 'today';

  @override
  String get homeAgoYesterday => 'yesterday';

  @override
  String homeAgoDays(int count) {
    return '$count d ago';
  }

  @override
  String homeAgoWeeks(int count) {
    return '$count wk ago';
  }

  @override
  String homeAgoMonths(int count) {
    return '$count mo ago';
  }

  @override
  String get homeConnectTmdbTitle => 'Connect TMDB';

  @override
  String get homeConnectTmdbMessage =>
      'MediaVore gets posters, release dates and new episodes from TMDB. You need a free personal key.';

  @override
  String get homeConnectTmdbAction => 'Connect to TMDB';

  @override
  String get discoverModeExplore => 'Explore';

  @override
  String get discoverModeSwipe => 'Swipe';

  @override
  String get discoverSearchHint => 'Films, series';

  @override
  String get discoverSearchHintWithBooks => 'Films, series, books';

  @override
  String get discoverSearchLabel => 'Search';

  @override
  String get discoverSearchClear => 'Clear the search';

  @override
  String get discoverTypeAll => 'All';

  @override
  String get discoverTypeFilms => 'Films';

  @override
  String get discoverTypeSeries => 'Series';

  @override
  String get discoverTypeBooks => 'Books';

  @override
  String get discoverTrendingWeek => 'Trending this week';

  @override
  String get discoverResults => 'Results';

  @override
  String discoverResultsCount(int count) {
    return 'Results · $count';
  }

  @override
  String get discoverNoResults => 'No results with these filters.';

  @override
  String discoverNoResultsFor(String query) {
    return 'No results for \"$query\".';
  }

  @override
  String get discoverOfflineMessage =>
      'check your connection and try again. Your lists and your history remain available.';

  @override
  String get discoverPeopleSection => 'People';

  @override
  String discoverBecauseYouLiked(String title) {
    return 'Because you liked $title';
  }

  @override
  String discoverBecauseYouWatched(String title) {
    return 'Because you watched $title';
  }

  @override
  String get discoverConnectTmdb => 'Connect to TMDB';

  @override
  String get libraryTypeAll => 'All';

  @override
  String libraryTypeChip(String label, int count) {
    return '$label · $count';
  }

  @override
  String libraryListRowLabel(String name, int count, int films, int series) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'no items',
    );
    String _temp1 = intl.Intl.pluralLogic(
      films,
      locale: localeName,
      other: '$films movies',
      one: '1 movie',
      zero: 'no movies',
    );
    String _temp2 = intl.Intl.pluralLogic(
      series,
      locale: localeName,
      other: '$series series',
      one: '1 series',
      zero: 'no series',
    );
    return '$name, $_temp0, $_temp1, $_temp2';
  }

  @override
  String libraryListImported(String name) {
    return 'List “$name” added';
  }

  @override
  String libraryListNameTaken(String name) {
    return 'A list named “$name” already exists';
  }

  @override
  String profileActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active days in the last 30 days',
      one: '1 active day in the last 30 days',
      zero: 'No active days in the last 30 days',
    );
    return '$_temp0';
  }

  @override
  String get profileMoviesWatched => 'Movies watched';

  @override
  String get profileEpisodesAndScreen => 'Episodes & screen';

  @override
  String profileScreenTime(int hours) {
    return '${hours}h screen time';
  }

  @override
  String get profileAllStats => 'All statistics';

  @override
  String profileAchievementsSeeAll(int unlocked, int total) {
    return 'See all · $unlocked of $total';
  }

  @override
  String get profileUnlocked => 'Unlocked';

  @override
  String get listsIncomingSharedTitle => 'Shared List Received';

  @override
  String listsIncomingSharedMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
    );
    return 'The shared list \"$name\" contains $_temp0. What would you like to do?';
  }

  @override
  String get listsCompareWithMine => 'Compare with one of my lists';

  @override
  String get listsImportOptionTitle => 'Import into library';

  @override
  String get listsCompareTitle => 'List Intersection';

  @override
  String listsCompareCommonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles in common',
      one: '1 title in common',
      zero: 'No titles in common',
    );
    return '$_temp0';
  }

  @override
  String get listsCompareHideSeen => 'Hide watched';

  @override
  String get listsCompareEmptyTitle => 'No common titles';

  @override
  String listsCompareEmptyMessage(String otherList, String myList) {
    return 'No movies or TV shows appear in both \"$otherList\" and \"$myList\".';
  }

  @override
  String listsCompareSaveAsList(int count) {
    return 'Save as new list ($count)';
  }

  @override
  String get listsCompareSaveAsListSuccess => 'List created successfully!';

  @override
  String get listsCompareShareIntersection => 'Share Common Selection';

  @override
  String listsCompareDefaultIntersectionName(String name) {
    return 'Common with $name';
  }

  @override
  String get mediaTypeMovie => 'Movie';

  @override
  String get mediaTypeTv => 'Series';

  @override
  String detailEpisodeRuntime(int minutes) {
    return '~$minutes min';
  }

  @override
  String detailSeenTimes(int count) {
    return 'Seen $count times';
  }

  @override
  String get detailSeriesFinished => 'Finished';

  @override
  String get rewatchSeriesAction => 'Rewatch series';

  @override
  String rewatchStartedMessage(String cycle) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      '2': '2nd',
      '3': '3rd',
      'other': '${cycle}th',
    });
    return '$_temp0 watch started · previous viewings are preserved';
  }

  @override
  String episodeAlreadySeenOn(String date) {
    return 'Already seen on $date';
  }

  @override
  String detailSeriesRewatching(String cycle, int season, int episode) {
    String _temp0 = intl.Intl.selectLogic(cycle, {
      '2': '2nd',
      '3': '3rd',
      'other': '${cycle}th',
    });
    return '$_temp0 watch · Next: S$season E$episode';
  }

  @override
  String detailSeriesWatchedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Watched $count times',
      one: 'Watched 1 time',
    );
    return '$_temp0';
  }

  @override
  String get detailMoreActions => 'More actions';

  @override
  String get detailShare => 'Share';

  @override
  String get detailShareHint => 'Link to the title page';

  @override
  String detailAddToList(String name) {
    return 'Add to “$name”';
  }

  @override
  String detailInListRemove(String name) {
    return 'In “$name”, tap to remove';
  }

  @override
  String get detailChooseList => 'Choose a list';

  @override
  String detailChooseListOthers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Choose another list (in $count others)',
      one: 'Choose another list (in 1 other)',
      zero: 'Choose another list',
    );
    return '$_temp0';
  }

  @override
  String detailAddedToList(String name) {
    return 'Added to “$name”';
  }

  @override
  String detailRemovedFromList(String name) {
    return 'Removed from “$name”';
  }

  @override
  String get detailReadMore => 'Read more';

  @override
  String get detailReadLess => 'Show less';

  @override
  String get detailInfos => 'Info';

  @override
  String get detailInfoDirection => 'Directed by';

  @override
  String get detailInfoCreation => 'Created by';

  @override
  String get detailOriginalTitle => 'Original title';

  @override
  String get detailCountry => 'Country';

  @override
  String get detailLanguage => 'Language';

  @override
  String detailCountryName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'US': 'United States',
      'GB': 'United Kingdom',
      'FR': 'France',
      'DE': 'Germany',
      'IT': 'Italy',
      'ES': 'Spain',
      'CA': 'Canada',
      'JP': 'Japan',
      'KR': 'South Korea',
      'CN': 'China',
      'HK': 'Hong Kong',
      'TW': 'Taiwan',
      'IN': 'India',
      'AU': 'Australia',
      'NZ': 'New Zealand',
      'BE': 'Belgium',
      'CH': 'Switzerland',
      'NL': 'Netherlands',
      'SE': 'Sweden',
      'NO': 'Norway',
      'DK': 'Denmark',
      'FI': 'Finland',
      'IS': 'Iceland',
      'IE': 'Ireland',
      'PT': 'Portugal',
      'BR': 'Brazil',
      'MX': 'Mexico',
      'AR': 'Argentina',
      'CL': 'Chile',
      'CO': 'Colombia',
      'RU': 'Russia',
      'PL': 'Poland',
      'CZ': 'Czechia',
      'AT': 'Austria',
      'HU': 'Hungary',
      'GR': 'Greece',
      'TR': 'Turkey',
      'IL': 'Israel',
      'IR': 'Iran',
      'EG': 'Egypt',
      'ZA': 'South Africa',
      'TH': 'Thailand',
      'ID': 'Indonesia',
      'PH': 'Philippines',
      'UA': 'Ukraine',
      'RO': 'Romania',
      'LU': 'Luxembourg',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String detailLanguageName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'en': 'English',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'es': 'Spanish',
      'pt': 'Portuguese',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'cn': 'Cantonese',
      'hi': 'Hindi',
      'ru': 'Russian',
      'sv': 'Swedish',
      'no': 'Norwegian',
      'da': 'Danish',
      'fi': 'Finnish',
      'nl': 'Dutch',
      'pl': 'Polish',
      'tr': 'Turkish',
      'ar': 'Arabic',
      'he': 'Hebrew',
      'fa': 'Persian',
      'th': 'Thai',
      'id': 'Indonesian',
      'el': 'Greek',
      'cs': 'Czech',
      'hu': 'Hungarian',
      'ro': 'Romanian',
      'uk': 'Ukrainian',
      'is': 'Icelandic',
      'ta': 'Tamil',
      'te': 'Telugu',
      'tl': 'Tagalog',
      'xx': 'No language',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String detailInYourLists(String lists) {
    return 'In your lists: $lists';
  }

  @override
  String detailRating(String rating) {
    return '$rating out of 10 on TMDB';
  }

  @override
  String inProgressTitle(int count) {
    return 'In progress · $count';
  }

  @override
  String inProgressPausedChip(int count) {
    return 'Paused · $count';
  }

  @override
  String get inProgressSortRecent => 'Recent';

  @override
  String get inProgressSortAlmostDone => 'Almost done';

  @override
  String get inProgressSortAlphabetical => 'A–Z';

  @override
  String get inProgressEmptyFiltered => 'Nothing matches these filters.';

  @override
  String inProgressMoreActions(String title) {
    return 'More actions for $title';
  }

  @override
  String get inProgressRemoveFromQuickAdd => 'Remove from quick add';

  @override
  String get inProgressRemoveFromQuickAddSubtitle =>
      'The series will no longer appear in In progress';

  @override
  String get inProgressOpenDetails => 'Open details';

  @override
  String get inProgressRemovedMessage => 'Series removed from quick add';

  @override
  String inProgressRemovedSection(int count) {
    return 'Removed from quick add · $count';
  }

  @override
  String get inProgressRestore => 'Restore';

  @override
  String inProgressRestoreLabel(String title) {
    return 'Restore $title';
  }

  @override
  String get inProgressRestoredMessage => 'Series restored';

  @override
  String get debugMissingEpisodesTitle => 'Debug — missing episodes';

  @override
  String get debugMissingEpisodesSubtitle =>
      'Expected next episodes that are not shown above.';

  @override
  String get debugRecompute => 'Recompute';

  @override
  String get debugNothingOmitted => 'Nothing omitted.';

  @override
  String debugGroupCount(String title, int count) {
    return '$title · $count';
  }

  @override
  String debugTitleWithEpisode(String title, String episode) {
    return '$title · $episode';
  }

  @override
  String debugTitleAfterEpisode(String title, String episode) {
    return '$title · after $episode';
  }

  @override
  String get debugQuickAddOptedOut => 'Removed from quick add';

  @override
  String get debugQuickAddOptedOutDetail => 'Removed manually';

  @override
  String get debugQuickAddNotReleased => 'Next episode not aired yet';

  @override
  String debugQuickAddNotReleasedDetail(String date) {
    return 'Airs on $date';
  }

  @override
  String get debugQuickAddNotReleasedUnknown => 'Air date unknown';

  @override
  String get debugQuickAddNotPopulated => 'Not added to quick add';

  @override
  String get debugQuickAddNotPopulatedDetail =>
      'Aired episode missing from quick add: try Recompute';

  @override
  String get debugQuickAddNoAirDate => 'No air date';

  @override
  String get debugQuickAddNoAirDateDetail =>
      'The episode has no known air date';

  @override
  String get debugQuickAddNoCacheData => 'Season data not cached';

  @override
  String get debugQuickAddNoCacheDataDetail =>
      'Tap Recompute to fetch the season';

  @override
  String upcomingTitle(int count) {
    return 'Upcoming · $count';
  }

  @override
  String get upcomingGroupReleased => 'Already released';

  @override
  String get upcomingGroupThisWeek => 'This week';

  @override
  String get upcomingGroupThisMonth => 'This month';

  @override
  String get upcomingGroupLater => 'Later';

  @override
  String upcomingGroupCount(String label, int count) {
    return '$label · $count';
  }

  @override
  String upcomingUndatedRow(int count) {
    return '$count without a date';
  }

  @override
  String get upcomingUndatedRowSubtitle =>
      'Renewed, planned, episodes to be dated';

  @override
  String upcomingUndatedSection(int count) {
    return 'No date · $count';
  }

  @override
  String get upcomingNothingPlanned => 'Nothing planned.';

  @override
  String upcomingDebugRow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hidden releases',
      one: '1 hidden release',
    );
    return 'Debug · $_temp0';
  }

  @override
  String get upcomingDebugRowSubtitle => 'See the reasons';

  @override
  String upcomingMarkSeen(String title) {
    return 'Mark $title as seen';
  }

  @override
  String upcomingSeenMessage(String title) {
    return 'Seen · $title';
  }

  @override
  String get upcomingDisableAlert => 'Disable the alert';

  @override
  String get upcomingDisableAlertSubtitle =>
      'The title will no longer appear in Upcoming';

  @override
  String upcomingAlertDisabledMessage(String title) {
    return 'Alert disabled · $title';
  }

  @override
  String get debugHiddenReleasesTitle => 'Debug — hidden releases';

  @override
  String get debugHiddenReleasesSubtitle =>
      'These items exist in the database but are omitted above.';

  @override
  String get debugReleaseAlreadySeen => 'Already seen';

  @override
  String get debugReleaseAlreadySeenDetail => 'Already in the history';

  @override
  String debugReleaseTooOld(int days) {
    return 'Aired more than $days days ago';
  }

  @override
  String debugReleaseTooOldDetail(String date) {
    return 'Stored air date: $date';
  }

  @override
  String get debugReleaseNoDate => 'No date stored';

  @override
  String get listsSortOrderManual => 'Manual order';

  @override
  String get listsSortOrderReleaseDate => 'Release date';

  @override
  String get listsSortOrderShuffle => 'Shuffle';

  @override
  String listsSortOrderReversed(String order) {
    return '$order (reversed)';
  }

  @override
  String listsHeaderSubtitle(int count, String order) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: '0 items',
    );
    return '$_temp0 · $order';
  }

  @override
  String get listsDisplayGrid2 => 'Grid (2 columns)';

  @override
  String get listsDisplayGrid3 => 'Grid (3 columns)';

  @override
  String get listsDisplayGrid4 => 'Grid (4 columns)';

  @override
  String get listsDisplayDetailedList => 'Detailed list';

  @override
  String get listsActionShare => 'Share list';

  @override
  String get listsActionSelect => 'Select';

  @override
  String get listsSelectAll => 'All';

  @override
  String get listsDeselectAll => 'None';

  @override
  String get listsRemove => 'Remove';

  @override
  String listsRemovedNotification(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items removed',
      one: '1 item removed',
    );
    return '$_temp0';
  }

  @override
  String get listsFillBySwiping => 'Fill by swiping';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filtersSortBy => 'Sort by';

  @override
  String get filtersSortRelevance => 'Relevance';

  @override
  String get filtersSortRating => 'Top rated';

  @override
  String get filtersSortRecent => 'Most recent';

  @override
  String get filtersSortOldest => 'Oldest';

  @override
  String get filtersPeriod => 'Release year';

  @override
  String get filtersPeriodAll => 'All';

  @override
  String get filtersPeriodBefore1990 => 'Before 1990';

  @override
  String get filtersPeriod1990s => '1990–1999';

  @override
  String get filtersPeriod2000s => '2000–2009';

  @override
  String get filtersPeriod2010s => '2010–2019';

  @override
  String get filtersPeriod2020plus => '2020 and later';

  @override
  String get filtersRatingTitle => 'Minimum rating';

  @override
  String get filtersRatingSubtitle => 'Movies and TV shows';

  @override
  String get filtersRatingAll => 'All';

  @override
  String get filtersRating7Plus => '7+';

  @override
  String get filtersRating8Plus => '8+';

  @override
  String get filtersDurationTitle => 'Duration';

  @override
  String get filtersDurationSubtitle => 'Movies only';

  @override
  String get filtersDurationNotApplicable => 'Not applicable to TV shows';

  @override
  String get filtersDurationAll => 'All';

  @override
  String get filtersDurationUnder105 => 'Under 1h 45m';

  @override
  String get filtersDuration105To150 => '1h 45m to 2h 30m';

  @override
  String get filtersDurationOver150 => 'Over 2h 30m';

  @override
  String get filtersHideSeen => 'Hide what I\'ve already seen or read';

  @override
  String get filtersClearAll => 'Clear all';

  @override
  String get filtersShowResults => 'Show results';

  @override
  String filtersShowNResults(int count) {
    return 'Show $count results';
  }

  @override
  String filtersChipSort(String sort) {
    return 'Sort: $sort';
  }

  @override
  String filtersChipRating(String rating) {
    return 'Rating $rating+';
  }

  @override
  String get filtersChipHideSeen => 'Unseen';

  @override
  String get historyToday => 'Today';

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String historyDayHeaderSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get historyModeChronologicalHint => 'Chronological view';

  @override
  String get historyModeLibraryHint => 'One entry per title';

  @override
  String get historyActionOpenDetail => 'Open details';

  @override
  String get historyActionDeleteViewing => 'Delete this viewing';

  @override
  String historyTimesSeen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seen $count times',
      one: 'Seen once',
    );
    return '$_temp0';
  }

  @override
  String historyTvLibrarySubtitle(int episodesSeen, int entries) {
    String _temp0 = intl.Intl.pluralLogic(
      episodesSeen,
      locale: localeName,
      other: '$episodesSeen episodes seen',
      one: '1 episode seen',
    );
    String _temp1 = intl.Intl.pluralLogic(
      entries,
      locale: localeName,
      other: '$entries entries',
      one: '1 entry',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String historyEpisodeSubtitle(int season, int episode) {
    return 'S$season E$episode';
  }

  @override
  String get historySegmentHistory => 'History';

  @override
  String get historySegmentLibrary => 'Library';

  @override
  String get historySortRecent => 'Date (newest)';

  @override
  String get historySortOldest => 'Date (oldest)';

  @override
  String get historySortTitleAsc => 'Title (A–Z)';

  @override
  String get historySortTitleDesc => 'Title (Z–A)';

  @override
  String get settingsSectionTracking => 'Tracking';

  @override
  String get settingsAdvancedTracking => 'Advanced tracking';

  @override
  String get settingsAdvancedTrackingSubtitle =>
      'Choose viewing date and time, edit past viewing logs';

  @override
  String get commonMarkAsSeenWithDots => 'Mark as seen…';

  @override
  String get seenRewatchAction => 'Rewatch';

  @override
  String get seenRewatchActionWithDots => 'Rewatch…';

  @override
  String seenSummaryOnce(String date) {
    return 'Seen once · on $date';
  }

  @override
  String seenSummaryMultiple(int count, String date) {
    return 'Seen $count times · last on $date';
  }

  @override
  String seenAddedMessage(String title) {
    return 'Marked as seen · $title';
  }

  @override
  String get seenFutureDateError => 'Viewing date cannot be in the future';

  @override
  String seenOrdinal(String ordinal) {
    String _temp0 = intl.Intl.selectLogic(ordinal, {
      '1': '1st',
      '2': '2nd',
      '3': '3rd',
      'other': '${ordinal}th',
    });
    return '$_temp0 viewing';
  }

  @override
  String get seenEditViewing => 'Edit date';

  @override
  String get seenVisionnagesSectionTitle => 'Viewings';

  @override
  String get settingsPreviousEpisodes => 'Unseen previous episodes';

  @override
  String get settingsPreviousEpisodesSubtitle =>
      'Behavior when marking an episode while earlier episodes are unseen';

  @override
  String get settingsPreviousEpisodesAsk => 'Ask';

  @override
  String get settingsPreviousEpisodesAll => 'All seen';

  @override
  String get settingsPreviousEpisodesOne => 'Leave unseen';

  @override
  String seenPreviousUnseenPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count previous episodes are unseen. Mark them as seen too?',
      one: '1 previous episode is unseen. Mark it as seen too?',
    );
    return '$_temp0';
  }

  @override
  String get seenPreviousMarkAll => 'Yes, mark all as seen';

  @override
  String get seenPreviousOnlyThis => 'No, only this episode';

  @override
  String get seenRememberChoice => 'Remember my choice';

  @override
  String seenBatchAddedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return 'Marked as seen · $_temp0';
  }

  @override
  String get detailWhereToWatch => 'Where to watch';

  @override
  String get detailWatchFlatrate => 'Stream';

  @override
  String get detailWatchRent => 'Rent';

  @override
  String get detailWatchBuy => 'Buy';

  @override
  String get detailWatchFree => 'Free';

  @override
  String get detailWatchJustWatchAttribution => 'Data provided by JustWatch';

  @override
  String get settingsWatchProvidersCountry => 'Platforms country';

  @override
  String get settingsWatchProvidersCountrySubtitle =>
      'Region used for streaming offers';

  @override
  String settingsWatchProvidersCountrySystem(String country) {
    return 'System ($country)';
  }

  @override
  String get settingsAboutJustWatch => 'Streaming data provided by JustWatch.';

  @override
  String get personDirecting => 'Directing / Creation';

  @override
  String get personActing => 'Acting';

  @override
  String personSeenCount(int seen, int total) {
    return '$seen of $total seen';
  }

  @override
  String get personOfflineNoData => 'No cached information for this person.';

  @override
  String sagaHeader(String name) {
    return 'Saga · $name';
  }

  @override
  String get sagaHeaderDefault => 'Saga';

  @override
  String sagaSeenCount(int seen, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      seen,
      locale: localeName,
      other: '$seen of $total films seen',
      one: '1 of $total films seen',
      zero: '0 of $total films seen',
    );
    return '$_temp0';
  }

  @override
  String get sagaCurrentItem => 'This title';

  @override
  String get sagaUpcoming => 'Upcoming';

  @override
  String sagaUpcomingWithYear(String year) {
    return 'Upcoming ($year)';
  }

  @override
  String sagaAddMissing(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count missing films to \"$list\"',
      one: 'Add 1 missing film to \"$list\"',
    );
    return '$_temp0';
  }

  @override
  String sagaMissingAdded(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count films added to \"$list\"',
      one: '1 film added to \"$list\"',
    );
    return '$_temp0';
  }

  @override
  String detailSeasonEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String detailSeasonSeenShort(int seen, int total) {
    return '$seen/$total seen';
  }

  @override
  String get togetherSessionSetup => 'Session Setup';

  @override
  String get togetherWeAreChoosing => 'We are choosing';

  @override
  String get togetherChoiceAny => 'Movie or Series';

  @override
  String get togetherChoiceMovie => 'A Movie';

  @override
  String get togetherChoiceTv => 'A Series';

  @override
  String get togetherMyListLabel => 'My list:';

  @override
  String get togetherWarningNotice =>
      'The QR code contains your list: anyone scanning it can view it.';

  @override
  String get togetherScanQrButton => 'Scan a friend\'s QR';

  @override
  String get togetherParticipantsTitle => 'Participants';

  @override
  String get togetherYouHost => 'Me (Host)';

  @override
  String togetherItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titles',
      one: '1 title',
      zero: '0 titles',
    );
    return '$_temp0';
  }

  @override
  String get togetherScanPrompt => 'Scan at least one friend to continue';

  @override
  String get togetherSeeCommonTitles => 'See common titles';

  @override
  String togetherCommonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count in common',
      one: '1 title in common',
      zero: 'No titles in common',
    );
    return '$_temp0';
  }

  @override
  String togetherAlmostSection(int k, int n) {
    return 'Almost: in $k of $n lists';
  }

  @override
  String togetherVoteLimitNotice(int count) {
    return 'Voting includes the 6 highest rated titles (out of $count)';
  }

  @override
  String get togetherEmptyCommonTitle => 'No titles in common';

  @override
  String get togetherEmptyCommonMessage =>
      'None of your titles match across all lists. Check the \"Almost\" section below!';

  @override
  String get togetherRandomPick => 'Random pick';

  @override
  String get togetherSwipeVote => 'Vote by swiping';

  @override
  String get togetherWatchThis => 'Let\'s watch this!';

  @override
  String get togetherResetSession => 'Reset session';

  @override
  String get togetherResetConfirm =>
      'Reset this session and clear all scanned participants?';

  @override
  String get togetherHideSeen => 'Hide watched';

  @override
  String togetherMultiQrPart(int current, int total) {
    return 'Part $current of $total';
  }

  @override
  String togetherScanNextPart(int current, int total) {
    return 'Scan next QR part ($current/$total)';
  }

  @override
  String get togetherLeaveVoteTitle => 'Leave voting';

  @override
  String get togetherLeaveVoteConfirm =>
      'Votes already cast will be lost. Participants will remain in the session.';

  @override
  String get togetherLeaveVoteButton => 'Leave';

  @override
  String get togetherYourTurn => 'Your turn to vote';

  @override
  String get togetherHostStartVote => 'I\'m voting';

  @override
  String togetherPassPhone(String name) {
    return 'Pass the phone to $name';
  }

  @override
  String get togetherParticipantStartVote => 'Let\'s go!';

  @override
  String togetherVoteProgress(int current, int total) {
    return 'Title $current of $total';
  }

  @override
  String get togetherVoteYes => 'Yes';

  @override
  String get togetherVoteNo => 'No';

  @override
  String get togetherTonightChoice => 'Tonight\'s choice';

  @override
  String get togetherUnanimousVote => 'Unanimous!';

  @override
  String togetherVoteCountFraction(int count, int total) {
    return '$count votes out of $total';
  }

  @override
  String get togetherTieBadge => 'Tie';

  @override
  String get togetherOtherTitles => 'Other titles';

  @override
  String get togetherReviewList => 'Review list';

  @override
  String togetherWatchingToast(String title) {
    return 'Enjoy watching $title!';
  }

  @override
  String swiperDiscardedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count discarded titles',
      one: '1 discarded title',
      zero: 'No discarded titles',
    );
    return '$_temp0';
  }

  @override
  String get swiperResetButton => 'Reset';

  @override
  String get swiperResetConfirmTitle => 'Reset swipe choices?';

  @override
  String get swiperResetConfirmMessage =>
      'Titles you previously discarded will be able to appear again in swipe mode. Your earned achievements remain unlocked.';

  @override
  String get swiperResetSuccessToast => 'Swipe choices reset';

  @override
  String get settingsAboutTmdb =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';
}
