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
  String get dataRefetchRuntimes => 'Refetch Media Runtimes';

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
  ) {
    return 'This file contains:\nSeen: $seen\nLikes: $likes\nNotifications: $notifications\nLists: $lists\n\nChoose how to apply the data to your current profile.';
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
  String get listsGridSize => 'Grid Size';

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
  String get listsShowQr => 'Show QR Code';

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
  String get listsCouldNotParseLink => 'Could not parse link';

  @override
  String get listsConfirmImport => 'Confirm Import';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get listsSortOptions => 'Sort Options';

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
  String get listsRemoveSelected => 'Remove selected';

  @override
  String get listsDisplayMode => 'Display Mode';

  @override
  String get listsEmpty => 'No items in this list.';

  @override
  String get listsSwitchList => 'Switch List';

  @override
  String listsItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

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
  String mediaSeasonShort(String count) {
    return '$count S';
  }

  @override
  String get seenRemoveLogTitle => 'Remove log?';

  @override
  String get seenRemoveLogMessage =>
      'Are you sure you want to remove this viewing entry from your history?';

  @override
  String get commonRemove => 'Remove';

  @override
  String get seenFilterSort => 'Filter & Sort';

  @override
  String get seenViewMode => 'View Mode';

  @override
  String get seenViewHistory => 'History (All episodes)';

  @override
  String get seenViewLibrary => 'Library (Unique titles)';

  @override
  String get seenSortBy => 'Sort by';

  @override
  String get seenSortDateNewest => 'Date (Newest)';

  @override
  String get seenSortDateOldest => 'Date (Oldest)';

  @override
  String get seenSortNameAsc => 'Name (A-Z)';

  @override
  String get seenSortNameDesc => 'Name (Z-A)';

  @override
  String get seenMediaType => 'Media Type';

  @override
  String get commonAll => 'All';

  @override
  String get commonMovies => 'Movies';

  @override
  String get commonTvShows => 'TV Shows';

  @override
  String get seenTitle => 'Seen History';

  @override
  String get seenSearchHint => 'Search history...';

  @override
  String get seenStatistics => 'Statistics';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get seenEmpty => 'No items seen yet.';

  @override
  String get seenNoMatches => 'No matches found.';

  @override
  String seenEpisodesSeen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes seen',
      one: '1 episode seen',
    );
    return '$_temp0';
  }

  @override
  String get seenCannotDeleteLibrary =>
      'Cannot delete from Library mode. Switch to History to remove entries.';

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
  String get statsOverview => 'Overview';

  @override
  String get statsDistribution => 'Distribution';

  @override
  String get statsSelectYear => 'Select Year';

  @override
  String get statsSelectPeriod => 'Select Period';

  @override
  String get statsTotalWatchTime => 'Total Watch Time';

  @override
  String statsDuration(int days, int hours, int minutes) {
    return '${days}d ${hours}h ${minutes}m';
  }

  @override
  String get statsEpisodes => 'Episodes';

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
  String statsPieLabel(String type, String percent) {
    return '$type\n$percent%';
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
  String get discoveryReleaseYear => 'Release Year';

  @override
  String get discoveryAnyYear => 'Any';

  @override
  String discoveryMinRating(String rating) {
    return 'Min Rating: $rating';
  }

  @override
  String get discoveryGenres => 'Genres';

  @override
  String get discoveryReset => 'Reset';

  @override
  String get discoveryApply => 'Apply';

  @override
  String get commonRetry => 'Retry';

  @override
  String get discoverySearchHint => 'Search within Discovery...';

  @override
  String get discoveryTitle => 'Discover';

  @override
  String get discoveryNoResults => 'No results found';

  @override
  String get discoveryClearFilters => 'Clear Filters';

  @override
  String get releaseEpisodeTba => 'Episode — date TBA';

  @override
  String get releaseReturning => 'Returning — new season planned';

  @override
  String get releasePlanned => 'Planned — no release date';

  @override
  String get notifTitle => 'Notification Center';

  @override
  String get notifForceRefresh => 'Force Refresh';

  @override
  String get notifTabReleases => 'Releases';

  @override
  String get notifTabQuickAdd => 'Quick Add';

  @override
  String get notifSyncing => 'Syncing releases...';

  @override
  String get notifNoReleases => 'No upcoming or recent releases.';

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
  String notifMarkedAsSeen(String title) {
    return 'Marked $title as seen';
  }

  @override
  String get notifNoNextEpisodes => 'No next episodes to track.';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String notifNextEpisode(int season, int episode) {
    return 'Next: Season $season, Episode $episode';
  }

  @override
  String get notifStreakOptedOut => 'Streak opted out of Quick Add';

  @override
  String get commonUndo => 'Undo';

  @override
  String get notifEpisode => 'episode';

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
  String get detailCreator => 'Creator';

  @override
  String get detailDirector => 'Director';

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
  String detailCreditLine(String role, String name) {
    return '$role: $name';
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
  String get detailWatchOn => 'Watch on:';

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
  String get seenOpenHistory => 'View History';

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
  String get seenViewingHistory => 'Viewing History';

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
  String get seenDateLabel => 'Date (DD/MM/YYYY)';

  @override
  String seenTimeLabel(String time) {
    return 'Time: $time';
  }

  @override
  String get seenCancelCaps => 'CANCEL';

  @override
  String get seenInvalidDate => 'Please enter a valid date (DD/MM/YYYY)';

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
  String achievementsUnlockedCount(int unlocked, int total) {
    return 'You\'ve unlocked $unlocked out of $total badges';
  }

  @override
  String achievementsUnlockedOn(String date) {
    return 'Unlocked on $date';
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
  String get progressRefetchDone => 'Done refetching data!';

  @override
  String progressProcessingItem(String title) {
    return 'Processing $title...';
  }

  @override
  String get progressSavingEntries => 'Saving entries...';

  @override
  String get progressImportComplete => 'Import complete';
}
