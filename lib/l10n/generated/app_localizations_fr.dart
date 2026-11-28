// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MediaVore';

  @override
  String get appLoading => 'Chargement de MediaVore...';

  @override
  String get appStartupFailedTitle => 'MediaVore n\'a pas pu démarrer';

  @override
  String get appStartupFailedMessage =>
      'Une erreur est survenue lors du chargement de vos données. Veuillez réessayer.';

  @override
  String get appStartupTechnicalDetails => 'Détails techniques';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonImport => 'Importer';

  @override
  String get navDiscover => 'Découvrir';

  @override
  String get navHistory => 'Historique';

  @override
  String get emptyStateSearchAction => 'Chercher un film ou une série';

  @override
  String get importListTitle => 'Importer une liste';

  @override
  String importListMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vous allez importer une liste de $count éléments.',
      one: 'Vous allez importer une liste de 1 élément.',
    );
    return '$_temp0';
  }

  @override
  String get importListNameLabel => 'Nom de la liste';

  @override
  String get importListNameHint => 'Saisissez un nom';

  @override
  String get tmdbOnboardingTitle => 'Connexion à TMDB';

  @override
  String get tmdbOnboardingWhy =>
      'MediaVore récupère les données des films et séries (affiches, synopsis, dates de sortie) sur The Movie Database (TMDB). TMDB demande à chaque utilisateur une clé personnelle gratuite.';

  @override
  String get tmdbOnboardingStepGetKey =>
      '1. Créez un compte TMDB gratuit, puis ouvrez sa page de paramètres de l\'API.';

  @override
  String get tmdbOnboardingOpenTmdb => 'Ouvrir la page API de TMDB';

  @override
  String get tmdbOnboardingStepPaste =>
      '2. Copiez le « Jeton d\'accès en lecture à l\'API » (ou la « Clé d\'API ») et collez-le ci-dessous.';

  @override
  String tmdbCredentialLinkCopied(String url) {
    return 'Impossible d\'ouvrir le navigateur. Lien copié : $url';
  }

  @override
  String get tmdbCredentialHint => 'Clé d\'API TMDB v3 ou jeton de lecture v4';

  @override
  String get tmdbCredentialPaste => 'Coller';

  @override
  String get tmdbCredentialShow => 'Afficher';

  @override
  String get tmdbCredentialHide => 'Masquer';

  @override
  String get tmdbCredentialVerifyAndSave => 'Vérifier et enregistrer';

  @override
  String get tmdbCredentialVerifying => 'Vérification auprès de TMDB…';

  @override
  String get tmdbCredentialSaved => 'Clé TMDB vérifiée et enregistrée.';

  @override
  String get tmdbCredentialInvalid =>
      'TMDB a refusé cette clé. Vérifiez que vous avez copié la clé d\'API ou le jeton de lecture en entier.';

  @override
  String tmdbCredentialCheckFailed(String reason) {
    return 'La clé n\'a pas pu être vérifiée : $reason';
  }

  @override
  String get tmdbCredentialSaveAnyway => 'Enregistrer sans vérifier';

  @override
  String get tmdbCredentialRemove => 'Supprimer la clé';

  @override
  String get tmdbCredentialLater =>
      'Vous pourrez définir votre clé d\'API plus tard dans Moi › Identifiant d\'API TMDB.';

  @override
  String get tmdbCredentialSkip => 'Plus tard';

  @override
  String get achievementUnlocked => 'Succès débloqué !';

  @override
  String get searchErrorMissingApiKey =>
      'Ajoutez votre clé d\'API TMDB dans les paramètres pour rechercher et découvrir des contenus.';

  @override
  String get searchErrorInvalidApiKey =>
      'Votre clé d\'API TMDB a été refusée. Vérifiez-la dans les paramètres.';

  @override
  String get searchErrorOffline =>
      'Vous êtes hors ligne. Vérifiez votre connexion et réessayez.';

  @override
  String get searchErrorServer =>
      'TMDB est indisponible pour le moment. Réessayez plus tard.';

  @override
  String get searchErrorUnknown =>
      'Une erreur est survenue lors du chargement des résultats.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Système';

  @override
  String get settingsThemeMode => 'Mode du thème';

  @override
  String get settingsThemeModeSystem => 'Système';

  @override
  String get settingsThemeModeLight => 'Clair';

  @override
  String get settingsThemeModeDark => 'Sombre';

  @override
  String get settingsLightTheme => 'Thème clair';

  @override
  String get settingsDarkTheme => 'Thème sombre';

  @override
  String get paletteNamePaper => 'Papier';

  @override
  String get paletteNameSand => 'Sable';

  @override
  String get paletteNameMist => 'Brume';

  @override
  String get paletteNameInk => 'Encre';

  @override
  String get paletteNameNight => 'Nuit';

  @override
  String get paletteNameOled => 'Noir OLED';

  @override
  String get paletteNameClassicLight => 'Clair classique';

  @override
  String get paletteNameParchment => 'Parchemin';

  @override
  String get paletteNameMint => 'Menthe';

  @override
  String get paletteNameSolarizedLight => 'Solarized clair';

  @override
  String get paletteNamePinky => 'Rosé';

  @override
  String get paletteNameClassicDark => 'Sombre classique';

  @override
  String get paletteNameSlate => 'Ardoise';

  @override
  String get paletteNameMidnight => 'Minuit';

  @override
  String get paletteNameEspresso => 'Expresso';

  @override
  String get profileTitle => 'Moi';

  @override
  String get profileAchievements => 'Succès';

  @override
  String get profileSettings => 'Paramètres';

  @override
  String get profileSettingsSubtitle => 'Apparence, affichage et préférences.';

  @override
  String get settingsHideNonReleased => 'Masquer les contenus non sortis';

  @override
  String get settingsHideNonReleasedSubtitle =>
      'N\'afficher que les films et épisodes déjà diffusés.';

  @override
  String get settingsStorage => 'Stockage et données';

  @override
  String get settingsStorageSubtitle =>
      'Gérer le cache, les exports et la base de l\'historique.';

  @override
  String get settingsTmdbCredential => 'Identifiant d\'API TMDB';

  @override
  String get settingsNotSet => 'Non défini';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsAboutDescription =>
      'Une application simple de suivi de films et séries, basée sur TMDB.';

  @override
  String get dataSectionCache => 'Gestion du cache';

  @override
  String get dataCacheSize => 'Taille du cache';

  @override
  String get dataCleanupCache => 'Nettoyer le cache';

  @override
  String get dataCleanupCacheSubtitle =>
      'Supprimer les anciens résultats de recherche et détails inutilisés.';

  @override
  String get dataCleanupCacheMessage =>
      'Les résultats de recherche et détails de plus de 60 jours absents de vos listes seront supprimés.';

  @override
  String get dataFillCache => 'Remplir le cache';

  @override
  String get dataFillCacheSubtitle =>
      'Mettre en cache tous les éléments de vos listes et de l\'historique récent pour un usage hors ligne.';

  @override
  String dataCachingTitles(int done, int total) {
    return 'Mise en cache des titres : $done / $total';
  }

  @override
  String get dataWipeCache => 'Vider tout le cache';

  @override
  String get dataWipeCacheSubtitle => 'Supprimer tout le contenu du cache.';

  @override
  String get dataWipeCacheMessage =>
      'TOUTES les affiches et tous les détails en cache seront supprimés. Une connexion internet sera nécessaire pour les revoir.';

  @override
  String get dataSectionData => 'Gestion des données';

  @override
  String get dataSeenDbSize => 'Taille de la base des vus';

  @override
  String get dataRefetchRuntimes => 'Récupérer les données manquantes';

  @override
  String get dataRefetchRuntimesSubtitle =>
      'Récupérer les durées et genres manquants de votre historique.';

  @override
  String get dataRefetchTitle => 'Récupérer les données';

  @override
  String get dataRefetchMessage =>
      'Votre historique sera analysé et les durées ou genres manquants seront récupérés depuis TMDb. Cela peut prendre un moment.';

  @override
  String get dataExportAll => 'Exporter toutes les données';

  @override
  String get dataExportAllSubtitle =>
      'Exporter vus, favoris, notifications et listes dans un seul fichier MDV.';

  @override
  String get dataSaveToDevice => 'Enregistrer sur l\'appareil';

  @override
  String get dataShareViaSystem => 'Partager';

  @override
  String get dataExportShareText => 'Export MediaVore';

  @override
  String get dataImportAll => 'Importer toutes les données';

  @override
  String get dataImportAllSubtitle =>
      'Importer vus, favoris, notifications et listes depuis un export MDV ou ZIP.';

  @override
  String get dataPopulateQuickAdd =>
      'Remplir l\'ajout rapide depuis l\'historique';

  @override
  String get dataPopulateQuickAddSubtitle =>
      'Calculer les prochains épisodes à partir de votre historique et les ajouter à l\'ajout rapide.';

  @override
  String get dataPopulateQuickAddTitle => 'Remplir l\'ajout rapide';

  @override
  String get dataPopulateQuickAddMessage =>
      'Les prochains épisodes non vus de vos séries seront calculés et ajoutés à l\'ajout rapide. Continuer ?';

  @override
  String get dataPopulateQuickAddDone =>
      'Ajout rapide rempli depuis l\'historique.';

  @override
  String get dataSectionAchievements => 'Données des succès';

  @override
  String get dataClearAchievements => 'Effacer la base des succès';

  @override
  String get dataClearAchievementsSubtitle =>
      'Supprimer toutes les étapes de succès enregistrées.';

  @override
  String get dataClearAchievementsTitle => 'Effacer les succès ?';

  @override
  String get dataClearAchievementsMessage =>
      'Toutes les dates de succès enregistrées seront supprimées de la base. Les succès calculés à partir de votre historique réapparaîtront automatiquement.';

  @override
  String get dataClearAchievementsDone => 'Base des succès effacée.';

  @override
  String get dataSectionDebug => 'Débogage';

  @override
  String get dataNotificationDebug => 'Débogage du centre de notifications';

  @override
  String get dataNotificationDebugSubtitle =>
      'Afficher les éléments masqués du centre de notifications et la raison de leur omission.';

  @override
  String get commonProcessing => 'Traitement...';

  @override
  String get dataExporting => 'Exportation des données…';

  @override
  String get dataReadingBackup => 'Lecture de la sauvegarde…';

  @override
  String get dataSaveExportDialog => 'Enregistrer l\'export';

  @override
  String get dataFileSaved => 'Fichier enregistré';

  @override
  String dataSaveFailed(String error) {
    return 'Échec de l\'enregistrement : $error. Essayez plutôt « Partager ».';
  }

  @override
  String get dataInvalidFile =>
      'Sélectionnez un fichier d\'export .mdv ou .zip valide.';

  @override
  String get dataImportPreviewTitle => 'Aperçu de l\'import';

  @override
  String dataImportPreviewMessage(
    int seen,
    int likes,
    int notifications,
    int lists,
    String warnings,
  ) {
    return 'Ce fichier contient :\nVus : $seen\nFavoris : $likes\nNotifications : $notifications\nListes : $lists\n$warnings\nChoisissez comment appliquer ces données à votre profil.';
  }

  @override
  String dataImportSkippedRows(int count) {
    return '$count ligne(s) invalide(s) seront ignorée(s) :';
  }

  @override
  String get dataImportedAppended => 'Importé (ajouté)';

  @override
  String get dataAppend => 'Ajouter';

  @override
  String get dataImportedMerged => 'Importé (fusionné)';

  @override
  String get dataMerge => 'Fusionner';

  @override
  String get dataImportedReplaced => 'Importé (remplacé)';

  @override
  String get dataReplace => 'Remplacer';

  @override
  String get dataImportFailed =>
      'Échec de l\'import : format de fichier invalide';

  @override
  String dataImportFailedReason(String reason) {
    return 'Échec de l\'import : $reason';
  }

  @override
  String get dataReplaceTitle => 'DANGER : remplacer l\'historique';

  @override
  String get dataReplaceMessage =>
      'Tout votre historique actuel sera supprimé et remplacé par les données du fichier. Cette action est irréversible. Êtes-vous vraiment sûr ?';

  @override
  String get dataReplaceConfirm => 'Oui, tout remplacer';

  @override
  String get commonProceed => 'Continuer';

  @override
  String get listsDisplayOptions => 'Options d\'affichage';

  @override
  String get listsSharingImporting => 'Partage et import';

  @override
  String get listsScanQr => 'Scanner un QR code';

  @override
  String get listsImportViaLink => 'Importer via un lien';

  @override
  String get listsShareWebLink => 'Partager un lien web (WhatsApp/SMS)';

  @override
  String listsShareLinkMessage(String list, String link) {
    return 'Découvre ma liste $list sur MediaVore : $link';
  }

  @override
  String listsQrShareMessage(String list) {
    return 'Scanne ce QR code pour importer ma liste $list sur MediaVore';
  }

  @override
  String listsQrShareError(String error) {
    return 'Erreur lors du partage du QR code : $error';
  }

  @override
  String listsShareTitle(String list) {
    return 'Partager $list';
  }

  @override
  String get listsQrCaption => 'Partage de liste MediaVore';

  @override
  String get listsQrHint =>
      'Scannez ce code avec un autre téléphone pour importer la liste.';

  @override
  String get listsShareQrImage => 'Partager l\'image du QR code';

  @override
  String get commonClose => 'Fermer';

  @override
  String get listsScanTitle => 'Scanner une liste MediaVore';

  @override
  String get listsScanHint =>
      'Pointez l\'appareil photo vers un QR code MediaVore';

  @override
  String get listsPasteLinkHint => 'Collez le lien partagé ici';

  @override
  String get listsShareLinkLabel => 'Lien de partage';

  @override
  String get listsInvalidLink => 'Format de lien invalide';

  @override
  String get listsConfirmImport => 'Confirmer l\'import';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get listsSortOptions => 'Options de tri';

  @override
  String get listsMoreActions => 'Plus d\'actions';

  @override
  String get listsSortManual => 'Ordre manuel';

  @override
  String get listsSortManualHint =>
      'Glissez-déposez les éléments pour les réordonner';

  @override
  String get listsSortReleaseDate => 'Date de sortie';

  @override
  String get listsSortReleaseDateHint => 'Trier par date de sortie';

  @override
  String get listsSortShuffle => 'Aléatoire';

  @override
  String get listsSortShuffleHint => 'Mélanger la liste';

  @override
  String get listsReverseOrder => 'Ordre inversé';

  @override
  String listsSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sélectionnés',
      one: '1 sélectionné',
      zero: '0 sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get listsWatchlist => 'À voir';

  @override
  String get listsEmpty => 'Aucun élément dans cette liste.';

  @override
  String get listsCreateNew => 'Créer une liste';

  @override
  String get listsNewList => 'Nouvelle liste';

  @override
  String get listsNameHint => 'Nom de la liste';

  @override
  String get commonCreate => 'Créer';

  @override
  String get listsDeleteList => 'Supprimer la liste';

  @override
  String listsDeleteListMessage(String list) {
    return 'Voulez-vous vraiment supprimer « $list » ? Tous les éléments de cette liste seront aussi retirés.';
  }

  @override
  String get commonDelete => 'Supprimer';

  @override
  String mediaSeasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saisons',
      one: '1 saison',
    );
    return '$_temp0';
  }

  @override
  String mediaRuntimeMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get seenRemoveLogTitle => 'Supprimer l\'entrée ?';

  @override
  String get seenRemoveLogMessage =>
      'Voulez-vous vraiment retirer ce visionnage de votre historique ?';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get seenSortBy => 'Trier par';

  @override
  String get seenMediaType => 'Type de média';

  @override
  String get commonMovies => 'Films';

  @override
  String get commonTvShows => 'Séries';

  @override
  String get seenTitle => 'Historique';

  @override
  String get seenSearchHint => 'Rechercher dans l\'historique...';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get seenEmpty => 'Rien de vu pour l\'instant.';

  @override
  String get seenEmptyHint =>
      'Marquez un film ou un épisode comme vu pour commencer votre historique.';

  @override
  String get seenNoMatches => 'Aucun résultat.';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get statsEmpty => 'Pas encore de données. À vos écrans !';

  @override
  String get statsToggleMetric => 'Changer d\'indicateur (entrées/durée)';

  @override
  String get statsAllTime => 'Tout';

  @override
  String get statsYear => 'Année';

  @override
  String get statsMonth => 'Mois';

  @override
  String get statsSelectYear => 'Choisir l\'année';

  @override
  String get statsSelectPeriod => 'Choisir la période';

  @override
  String get statsPreviousPeriod => 'Période précédente';

  @override
  String get statsNextPeriod => 'Période suivante';

  @override
  String get statsTotalWatchTime => 'Temps de visionnage total';

  @override
  String statsDuration(int days, int hours, int minutes) {
    return '$days j $hours h $minutes min';
  }

  @override
  String statsHallOfFame(String metric) {
    return 'Palmarès ($metric)';
  }

  @override
  String get statsMostWatchedMovie => 'Film le plus vu';

  @override
  String get statsMostWatchedSeries => 'Série la plus vue';

  @override
  String get statsMostWatchedEpisode => 'Épisode le plus vu';

  @override
  String get statsActivityLogs => 'Activité (entrées)';

  @override
  String get statsActivityMinutes => 'Activité (minutes)';

  @override
  String statsLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées',
      one: '1 entrée',
      zero: '0 entrée',
    );
    return '$_temp0';
  }

  @override
  String statsHours(String hours) {
    return '$hours h';
  }

  @override
  String get statsNoActivity => 'Aucune activité';

  @override
  String statsTooltip(String label, int value, String unit) {
    return '$label\n$value $unit';
  }

  @override
  String statsMediaSplit(String metric) {
    return 'Films / séries ($metric)';
  }

  @override
  String statsTopGenres(String metric) {
    return 'Genres favoris (par $metric)';
  }

  @override
  String statsGenreValue(String value, String percent) {
    return '$value ($percent %)';
  }

  @override
  String get statsMetricLogs => 'entrées';

  @override
  String get statsMetricTime => 'durée';

  @override
  String get statsNoDataForPeriod =>
      'Aucune donnée de visionnage pour cette période';

  @override
  String get statsDecades => 'Par décennie de sortie';

  @override
  String get statsDecadeBefore1990 => 'Avant 1990';

  @override
  String get statsDecadeAfter2020 => '2020 et après';

  @override
  String statsAverageRating(String rating) {
    return '$rating ★';
  }

  @override
  String get statsSeriesProgression => 'Séries';

  @override
  String statsSeriesProgressCount(int watched, int total, String percent) {
    return '$watched / $total épisodes ($percent %)';
  }

  @override
  String statsSeriesWatchedEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes',
      one: '1 épisode',
      zero: '0 épisode',
    );
    return '$_temp0';
  }

  @override
  String get statsListsAndDiscovery => 'Listes et découverte';

  @override
  String statsWatchlistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres à voir',
      one: '1 titre à voir',
      zero: '0 titre à voir',
    );
    return '$_temp0';
  }

  @override
  String statsCustomListsCount(int listsCount, int itemsCount) {
    String _temp0 = intl.Intl.pluralLogic(
      listsCount,
      locale: localeName,
      other: '$listsCount listes perso',
      one: '1 liste perso',
      zero: '0 liste perso',
    );
    return '$_temp0 ($itemsCount titres)';
  }

  @override
  String get statsFooterDatedHistory => 'Calculé sur l\'historique daté.';

  @override
  String statsMoviesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count films',
      one: '1 film',
      zero: '0 film',
    );
    return '$_temp0';
  }

  @override
  String statsEpisodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes',
      one: '1 épisode',
      zero: '0 épisode',
    );
    return '$_temp0';
  }

  @override
  String get genreAction => 'Action';

  @override
  String get genreAdventure => 'Aventure';

  @override
  String get genreAnimation => 'Animation';

  @override
  String get genreComedy => 'Comédie';

  @override
  String get genreCrime => 'Crime';

  @override
  String get genreDocumentary => 'Documentaire';

  @override
  String get genreDrama => 'Drame';

  @override
  String get genreFamily => 'Familial';

  @override
  String get genreFantasy => 'Fantastique';

  @override
  String get genreHistory => 'Histoire';

  @override
  String get genreHorror => 'Horreur';

  @override
  String get genreMusic => 'Musique';

  @override
  String get genreMystery => 'Mystère';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreSciFi => 'Science-fiction';

  @override
  String get genreTvMovie => 'Téléfilm';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreWar => 'Guerre';

  @override
  String get genreWestern => 'Western';

  @override
  String get genreActionAdventure => 'Action et aventure';

  @override
  String get genreKids => 'Enfants';

  @override
  String get genreNews => 'Actualités';

  @override
  String get genreReality => 'Téléréalité';

  @override
  String get genreSciFiFantasy => 'Science-fiction et fantastique';

  @override
  String get genreSoap => 'Feuilleton';

  @override
  String get genreTalk => 'Talk-show';

  @override
  String get genreWarPolitics => 'Guerre et politique';

  @override
  String get discoveryFiltersTitle => 'Filtres de découverte';

  @override
  String get discoveryBoth => 'Les deux';

  @override
  String get discoveryGenres => 'Genres';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get discoveryTitle => 'Découvrir';

  @override
  String get discoveryClearFilters => 'Effacer les filtres';

  @override
  String get releaseEpisodeTba => 'Épisode — date à venir';

  @override
  String get releaseReturning => 'Renouvelée — nouvelle saison prévue';

  @override
  String get releasePlanned => 'Prévu — pas de date de sortie';

  @override
  String get notifNoReleases => 'Aucune sortie à venir ou récente.';

  @override
  String get notifNoReleasesHint =>
      'Les sorties des films et séries de votre liste À voir ou avec une alerte apparaissent ici.';

  @override
  String notifReleaseDate(String released, String date) {
    String _temp0 = intl.Intl.selectLogic(released, {
      'true': 'Sorti le',
      'other': 'Sortie le',
    });
    return '$_temp0 $date';
  }

  @override
  String get commonMarkAsSeen => 'Marquer comme vu';

  @override
  String get notifNoNextEpisodes => 'Aucun prochain épisode à suivre.';

  @override
  String get commonUnknown => 'Inconnu';

  @override
  String get commonUndo => 'Annuler';

  @override
  String get detailOfflineSeason =>
      'Impossible de charger les détails de la saison hors ligne.';

  @override
  String get detailNoHistoryToExport =>
      'Aucun historique à exporter pour ce titre.';

  @override
  String detailHistoryShareText(String title) {
    return 'Historique de visionnage de $title';
  }

  @override
  String get detailSaveHistoryDialog => 'Enregistrer l\'historique';

  @override
  String detailSaveFailed(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String get detailExportHistory => 'Exporter l\'historique de ce titre';

  @override
  String detailProgress(int seen, int total) {
    return 'Progression : $seen / $total épisodes vus';
  }

  @override
  String get detailOfflineMode => 'Mode hors ligne';

  @override
  String get detailOfflineMessage =>
      'Les informations détaillées ne sont pas disponibles sans internet.';

  @override
  String get commonTryAgain => 'Réessayer';

  @override
  String detailSeasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saisons',
      one: '1 saison',
    );
    return '$_temp0';
  }

  @override
  String detailEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes',
      one: '1 épisode',
    );
    return '$_temp0';
  }

  @override
  String get detailOverview => 'Synopsis';

  @override
  String get detailSeasons => 'Saisons';

  @override
  String detailSeasonName(int number) {
    return 'Saison $number';
  }

  @override
  String detailSeasonProgress(int seen, int total) {
    return '$seen / $total épisodes vus';
  }

  @override
  String get detailCast => 'Distribution';

  @override
  String get detailSimilar => 'Similaires';

  @override
  String get detailRecommendations => 'Recommandations';

  @override
  String get detailTrailers => 'Bandes-annonces';

  @override
  String get statusReleased => 'Sorti';

  @override
  String get statusReturning => 'Série renouvelée';

  @override
  String get statusEnded => 'Terminée';

  @override
  String get statusCanceled => 'Annulée';

  @override
  String get statusInProduction => 'En production';

  @override
  String get statusPostProduction => 'Post-production';

  @override
  String get statusPlanned => 'Prévu';

  @override
  String get statusRumored => 'Rumeur';

  @override
  String get statusPilot => 'Pilote';

  @override
  String get seenEpisodesSeenTitle => 'Épisodes vus';

  @override
  String get seenSeen => 'Vu';

  @override
  String seenEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes',
      one: '1 épisode',
      zero: '0 épisode',
    );
    return '$_temp0';
  }

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get seenClearHistory => 'Effacer l\'historique';

  @override
  String seenClearHistoryMessage(String title) {
    return 'Voulez-vous vraiment effacer tout l\'historique de « $title » ?';
  }

  @override
  String get seenClearAll => 'Tout effacer';

  @override
  String get seenAddViewing => 'Ajouter un visionnage';

  @override
  String get seenNoHistory => 'Aucun historique pour ce titre.';

  @override
  String get seenRemoveAllHistory => 'Supprimer tout l\'historique';

  @override
  String get seenUseCalendar => 'Utiliser le calendrier';

  @override
  String get seenTypeDate => 'Saisir la date';

  @override
  String get seenDateLabel => 'Date (JJ/MM/AAAA)';

  @override
  String get seenDateHint => '31/12/2023';

  @override
  String seenTimeLabel(String time) {
    return 'Heure : $time';
  }

  @override
  String get seenCancelCaps => 'ANNULER';

  @override
  String get seenInvalidDate => 'Saisissez une date valide (JJ/MM/AAAA)';

  @override
  String get seenLogViewing => 'ENREGISTRER';

  @override
  String get likeUnlike => 'Retirer des favoris';

  @override
  String get likeLike => 'Ajouter aux favoris';

  @override
  String get notifyDisable => 'Désactiver les notifications';

  @override
  String get notifyEnable => 'M\'avertir à la sortie';

  @override
  String get watchlistRemove => 'Retirer de la liste À voir';

  @override
  String get watchlistAdd => 'Ajouter à la liste À voir';

  @override
  String watchNext(int season, int episode) {
    return 'À suivre : S$season E$episode';
  }

  @override
  String actorLoadFailed(String error) {
    return 'Impossible de charger les détails de l\'acteur : $error';
  }

  @override
  String get actorBiography => 'Biographie';

  @override
  String get actorKnownFor => 'Connu pour';

  @override
  String get achievementsOverall => 'Progression globale';

  @override
  String get achievementsCategoryMovies => 'Films';

  @override
  String get achievementsCategoryTv => 'Séries';

  @override
  String get achievementsCategoryBooks => 'Livres';

  @override
  String get achievementsCategoryDiscovery => 'Découverte';

  @override
  String get achievementsCategoryTogether => 'Ensemble';

  @override
  String get achievementsCategoryRegularity => 'Régularité';

  @override
  String achievementsUnlockedCount(int unlocked, int total) {
    return 'Vous avez débloqué $unlocked badges sur $total';
  }

  @override
  String achievementsUnlockedOn(String date) {
    return 'Débloqué le $date';
  }

  @override
  String achievementsChallengesCompleted(int completed, int total) {
    return '$completed / $total défis terminés';
  }

  @override
  String achievementsLevelProgress(int unlocked, int total) {
    return 'Niveau $unlocked/$total';
  }

  @override
  String achievementsLevelTitle(int level, String title) {
    return 'Niveau $level · $title';
  }

  @override
  String achievementsNextLevel(String title, String progress) {
    return 'Suivant : $title · $progress';
  }

  @override
  String get achievementsAllLevelsCompleted => 'Tous les niveaux terminés';

  @override
  String achievementLevelUnlocked(int level) {
    return 'Niveau $level débloqué !';
  }

  @override
  String get progressImportingAll => 'Import de toutes les données...';

  @override
  String get progressDone => 'Terminé !';

  @override
  String progressError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get progressRefetchingRuntimes =>
      'Récupération des durées manquantes...';

  @override
  String progressRefetchingItem(String title) {
    return 'Récupération de $title...';
  }

  @override
  String progressProcessingItem(String title) {
    return 'Traitement de $title...';
  }

  @override
  String get progressSavingEntries => 'Enregistrement des entrées...';

  @override
  String get progressImportComplete => 'Import terminé';

  @override
  String get mediaKindMovie => 'Film';

  @override
  String get mediaKindSeries => 'Série';

  @override
  String get mediaKindBook => 'Livre';

  @override
  String get swiperTitle => 'Swiper';

  @override
  String get swiperAddTo => 'Ajouter à';

  @override
  String get swiperDiscard => 'Écarter';

  @override
  String get swiperAdd => 'Ajouter';

  @override
  String get swiperUndo => 'Annuler';

  @override
  String get swiperEmptyTitle => 'Plus de films';

  @override
  String get swiperEmptyMessage =>
      'Vous avez passé en revue tous les films disponibles pour le moment.';

  @override
  String swiperSessionStats(int added, int discarded) {
    return '$added ajoutés · $discarded écartés';
  }

  @override
  String get swiperSettingTitle => 'Mode Swipe dans Découvrir';

  @override
  String get swiperSettingSubtitle =>
      'Afficher le mode Swipe pour découvrir des films carte par carte';

  @override
  String swiperSagaBadge(int count) {
    return 'Saga ($count films)';
  }

  @override
  String get commonSeeAll => 'Tout voir';

  @override
  String get offlineBannerTitle => 'Hors ligne';

  @override
  String get posterInProgress => 'En cours';

  @override
  String get posterLiked => 'Aimé';

  @override
  String posterRating(String rating) {
    return 'Note $rating';
  }

  @override
  String get navHome => 'Accueil';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navTogether => 'Ensemble';

  @override
  String get navMe => 'Moi';

  @override
  String get librarySectionLists => 'Listes';

  @override
  String get homeTitle => 'Ce soir';

  @override
  String get homeOfflineMessage =>
      'les sorties seront actualisées au retour du réseau.';

  @override
  String get homeResume => 'Reprendre';

  @override
  String homeEpisodeCode(int season, int episode) {
    return 'S$season É$episode';
  }

  @override
  String homeNextEpisode(String episode) {
    return 'Prochain : $episode';
  }

  @override
  String homeMarkEpisodeSeen(String episode, String title) {
    return 'Marquer $episode de $title comme vu';
  }

  @override
  String homeEpisodeSeenMessage(String episode, String title) {
    return '$episode vu · $title';
  }

  @override
  String get homeTonightTitle => 'À voir ce soir';

  @override
  String get homeTonightOtherIdea => 'Autre idée';

  @override
  String homeTonightSource(String list, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres pas encore vus',
      one: '1 titre pas encore vu',
    );
    return 'Depuis votre liste « $list » · $_temp0';
  }

  @override
  String get homeChooseTogether => 'Choisir à plusieurs';

  @override
  String get homeChooseTogetherSubtitle => 'Comparez vos listes et votez';

  @override
  String get homeEmptyTitle => 'Rien de prévu ce soir.';

  @override
  String homeEmptyMessage(String list) {
    return 'Ajoutez des films ou des séries à votre liste « $list » pour les retrouver ici.';
  }

  @override
  String get homeEmptyAction => 'Découvrir des titres';

  @override
  String homeAlsoInProgress(int count) {
    return 'Aussi en cours · $count';
  }

  @override
  String homeSeeAllCount(int count) {
    return 'Tout voir ($count)';
  }

  @override
  String get homeRecentAreInResume =>
      'Les plus récents sont dans « Reprendre ».';

  @override
  String homeFilterAll(int count) {
    return 'Tout · $count';
  }

  @override
  String homeFilterSeries(int count) {
    return 'Séries · $count';
  }

  @override
  String homeFilterBooks(int count) {
    return 'Livres · $count';
  }

  @override
  String homeMoreInProgress(int count) {
    return '$count de plus, tout voir';
  }

  @override
  String homePausedTitle(int count) {
    return '$count en pause';
  }

  @override
  String homePausedSubtitle(int days) {
    return 'Sans activité depuis plus de $days jours';
  }

  @override
  String get homeAgoToday => 'aujourd\'hui';

  @override
  String get homeAgoYesterday => 'hier';

  @override
  String homeAgoDays(int count) {
    return 'il y a $count j';
  }

  @override
  String homeAgoWeeks(int count) {
    return 'il y a $count sem.';
  }

  @override
  String homeAgoMonths(int count) {
    return 'il y a $count mois';
  }

  @override
  String get homeConnectTmdbTitle => 'Connecter TMDB';

  @override
  String get homeConnectTmdbMessage =>
      'MediaVore récupère les affiches, les dates de sortie et les nouveaux épisodes sur TMDB. Il faut une clé personnelle, gratuite.';

  @override
  String get homeConnectTmdbAction => 'Connexion à TMDB';

  @override
  String get discoverModeExplore => 'Explorer';

  @override
  String get discoverModeSwipe => 'Swiper';

  @override
  String get discoverSearchHint => 'Films, séries';

  @override
  String get discoverSearchHintWithBooks => 'Films, séries, livres';

  @override
  String get discoverSearchLabel => 'Rechercher';

  @override
  String get discoverSearchClear => 'Effacer la recherche';

  @override
  String get discoverTypeAll => 'Tout';

  @override
  String get discoverTypeFilms => 'Films';

  @override
  String get discoverTypeSeries => 'Séries';

  @override
  String get discoverTypeBooks => 'Livres';

  @override
  String get discoverTrendingWeek => 'Tendances de la semaine';

  @override
  String get discoverResults => 'Résultats';

  @override
  String discoverResultsCount(int count) {
    return 'Résultats · $count';
  }

  @override
  String get discoverNoResults => 'Aucun résultat avec ces filtres.';

  @override
  String discoverNoResultsFor(String query) {
    return 'Aucun résultat pour « $query ».';
  }

  @override
  String get discoverOfflineMessage =>
      'vérifiez votre connexion et réessayez. Vos listes et votre historique restent disponibles.';

  @override
  String get discoverPeopleSection => 'Personnes';

  @override
  String discoverBecauseYouLiked(String title) {
    return 'Parce que vous avez aimé $title';
  }

  @override
  String discoverBecauseYouWatched(String title) {
    return 'Parce que vous regardez $title';
  }

  @override
  String get discoverConnectTmdb => 'Connexion à TMDB';

  @override
  String get libraryTypeAll => 'Tout';

  @override
  String libraryTypeChip(String label, int count) {
    return '$label · $count';
  }

  @override
  String libraryListRowLabel(String name, int count, int films, int series) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
      zero: 'aucun élément',
    );
    String _temp1 = intl.Intl.pluralLogic(
      films,
      locale: localeName,
      other: '$films films',
      one: '1 film',
      zero: 'aucun film',
    );
    String _temp2 = intl.Intl.pluralLogic(
      series,
      locale: localeName,
      other: '$series séries',
      one: '1 série',
      zero: 'aucune série',
    );
    return '$name, $_temp0, $_temp1, $_temp2';
  }

  @override
  String libraryListImported(String name) {
    return 'Liste « $name » ajoutée';
  }

  @override
  String libraryListNameTaken(String name) {
    return 'Une liste nommée « $name » existe déjà';
  }

  @override
  String profileActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours actifs sur les 30 derniers',
      one: '1 jour actif sur les 30 derniers',
      zero: 'Aucun jour actif sur les 30 derniers',
    );
    return '$_temp0';
  }

  @override
  String get profileMoviesWatched => 'Films vus';

  @override
  String get profileEpisodesAndScreen => 'Épisodes et écran';

  @override
  String profileScreenTime(int hours) {
    return '$hours h d\'écran';
  }

  @override
  String get profileAllStats => 'Toutes les statistiques';

  @override
  String profileAchievementsSeeAll(int unlocked, int total) {
    return 'Tout voir · $unlocked sur $total';
  }

  @override
  String get profileUnlocked => 'Débloqué';

  @override
  String get listsIncomingSharedTitle => 'Liste partagée reçue';

  @override
  String listsIncomingSharedMessage(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return 'La liste partagée « $name » contient $_temp0. Que souhaitez-vous faire ?';
  }

  @override
  String get listsCompareWithMine => 'Comparer avec une de mes listes';

  @override
  String get listsImportOptionTitle => 'Importer dans ma bibliothèque';

  @override
  String get listsCompareTitle => 'Intersection de listes';

  @override
  String listsCompareCommonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres en commun',
      one: '1 titre en commun',
      zero: 'Aucun titre en commun',
    );
    return '$_temp0';
  }

  @override
  String get listsCompareHideSeen => 'Masquer mes vus';

  @override
  String get listsCompareEmptyTitle => 'Aucun titre en commun';

  @override
  String listsCompareEmptyMessage(String otherList, String myList) {
    return 'Aucun film ou série ne figure à la fois dans « $otherList » et « $myList ».';
  }

  @override
  String listsCompareSaveAsList(int count) {
    return 'Créer une liste ($count)';
  }

  @override
  String get listsCompareSaveAsListSuccess => 'Liste créée avec succès !';

  @override
  String get listsCompareShareIntersection => 'Partager la sélection commune';

  @override
  String listsCompareDefaultIntersectionName(String name) {
    return 'En commun avec $name';
  }

  @override
  String get mediaTypeMovie => 'Film';

  @override
  String get mediaTypeTv => 'Série';

  @override
  String detailEpisodeRuntime(int minutes) {
    return '~$minutes min';
  }

  @override
  String detailSeenTimes(int count) {
    return 'Vu $count fois';
  }

  @override
  String get detailSeriesFinished => 'Terminée';

  @override
  String get rewatchSeriesAction => 'Revoir la série';

  @override
  String rewatchStartedMessage(String cycle) {
    return '${cycle}e visionnage commencé · les précédents sont conservés';
  }

  @override
  String episodeAlreadySeenOn(String date) {
    return 'Déjà vu le $date';
  }

  @override
  String detailSeriesRewatching(String cycle, int season, int episode) {
    return '${cycle}e visionnage · Prochain : S$season É$episode';
  }

  @override
  String detailSeriesWatchedTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vue $count fois',
      one: 'Vue 1 fois',
    );
    return '$_temp0';
  }

  @override
  String get detailMoreActions => 'Plus d\'actions';

  @override
  String get detailShare => 'Partager';

  @override
  String get detailShareHint => 'Lien vers la fiche';

  @override
  String detailAddToList(String name) {
    return 'Ajouter à « $name »';
  }

  @override
  String detailInListRemove(String name) {
    return 'Dans « $name », toucher pour retirer';
  }

  @override
  String get detailChooseList => 'Choisir une liste';

  @override
  String detailChooseListOthers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Choisir une autre liste (dans $count autres)',
      one: 'Choisir une autre liste (dans 1 autre)',
      zero: 'Choisir une autre liste',
    );
    return '$_temp0';
  }

  @override
  String detailAddedToList(String name) {
    return 'Ajouté à « $name »';
  }

  @override
  String detailRemovedFromList(String name) {
    return 'Retiré de « $name »';
  }

  @override
  String get detailReadMore => 'Lire la suite';

  @override
  String get detailReadLess => 'Réduire';

  @override
  String get detailInfos => 'Infos';

  @override
  String get detailInfoDirection => 'Réalisation';

  @override
  String get detailInfoCreation => 'Création';

  @override
  String get detailOriginalTitle => 'Titre original';

  @override
  String get detailCountry => 'Pays';

  @override
  String get detailLanguage => 'Langue';

  @override
  String detailCountryName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'US': 'États-Unis',
      'GB': 'Royaume-Uni',
      'FR': 'France',
      'DE': 'Allemagne',
      'IT': 'Italie',
      'ES': 'Espagne',
      'CA': 'Canada',
      'JP': 'Japon',
      'KR': 'Corée du Sud',
      'CN': 'Chine',
      'HK': 'Hong Kong',
      'TW': 'Taïwan',
      'IN': 'Inde',
      'AU': 'Australie',
      'NZ': 'Nouvelle-Zélande',
      'BE': 'Belgique',
      'CH': 'Suisse',
      'NL': 'Pays-Bas',
      'SE': 'Suède',
      'NO': 'Norvège',
      'DK': 'Danemark',
      'FI': 'Finlande',
      'IS': 'Islande',
      'IE': 'Irlande',
      'PT': 'Portugal',
      'BR': 'Brésil',
      'MX': 'Mexique',
      'AR': 'Argentine',
      'CL': 'Chili',
      'CO': 'Colombie',
      'RU': 'Russie',
      'PL': 'Pologne',
      'CZ': 'Tchéquie',
      'AT': 'Autriche',
      'HU': 'Hongrie',
      'GR': 'Grèce',
      'TR': 'Turquie',
      'IL': 'Israël',
      'IR': 'Iran',
      'EG': 'Égypte',
      'ZA': 'Afrique du Sud',
      'TH': 'Thaïlande',
      'ID': 'Indonésie',
      'PH': 'Philippines',
      'UA': 'Ukraine',
      'RO': 'Roumanie',
      'LU': 'Luxembourg',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String detailLanguageName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'en': 'Anglais',
      'fr': 'Français',
      'de': 'Allemand',
      'it': 'Italien',
      'es': 'Espagnol',
      'pt': 'Portugais',
      'ja': 'Japonais',
      'ko': 'Coréen',
      'zh': 'Chinois',
      'cn': 'Cantonais',
      'hi': 'Hindi',
      'ru': 'Russe',
      'sv': 'Suédois',
      'no': 'Norvégien',
      'da': 'Danois',
      'fi': 'Finnois',
      'nl': 'Néerlandais',
      'pl': 'Polonais',
      'tr': 'Turc',
      'ar': 'Arabe',
      'he': 'Hébreu',
      'fa': 'Persan',
      'th': 'Thaï',
      'id': 'Indonésien',
      'el': 'Grec',
      'cs': 'Tchèque',
      'hu': 'Hongrois',
      'ro': 'Roumain',
      'uk': 'Ukrainien',
      'is': 'Islandais',
      'ta': 'Tamoul',
      'te': 'Télougou',
      'tl': 'Tagalog',
      'xx': 'Sans dialogue',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String detailInYourLists(String lists) {
    return 'Dans vos listes : $lists';
  }

  @override
  String detailRating(String rating) {
    return '$rating sur 10 sur TMDB';
  }

  @override
  String inProgressTitle(int count) {
    return 'En cours · $count';
  }

  @override
  String inProgressPausedChip(int count) {
    return 'En pause · $count';
  }

  @override
  String get inProgressSortRecent => 'Récents';

  @override
  String get inProgressSortAlmostDone => 'Presque finis';

  @override
  String get inProgressSortAlphabetical => 'A–Z';

  @override
  String get inProgressEmptyFiltered =>
      'Aucun titre ne correspond à ces filtres.';

  @override
  String inProgressMoreActions(String title) {
    return 'Autres actions pour $title';
  }

  @override
  String get inProgressRemoveFromQuickAdd => 'Retirer de l\'ajout rapide';

  @override
  String get inProgressRemoveFromQuickAddSubtitle =>
      'La série n\'apparaîtra plus dans En cours';

  @override
  String get inProgressOpenDetails => 'Ouvrir la fiche';

  @override
  String get inProgressRemovedMessage => 'Série retirée de l\'ajout rapide';

  @override
  String inProgressRemovedSection(int count) {
    return 'Retirées de l\'ajout rapide · $count';
  }

  @override
  String get inProgressRestore => 'Rétablir';

  @override
  String inProgressRestoreLabel(String title) {
    return 'Rétablir $title';
  }

  @override
  String get inProgressRestoredMessage => 'Série rétablie';

  @override
  String get debugMissingEpisodesTitle => 'Debug — épisodes manquants';

  @override
  String get debugMissingEpisodesSubtitle =>
      'Prochains épisodes attendus mais non affichés ci-dessus.';

  @override
  String get debugRecompute => 'Recalculer';

  @override
  String get debugNothingOmitted => 'Rien d\'omis.';

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
    return '$title · après $episode';
  }

  @override
  String get debugQuickAddOptedOut => 'Retirée de l\'ajout rapide';

  @override
  String get debugQuickAddOptedOutDetail => 'Retirée manuellement';

  @override
  String get debugQuickAddNotReleased => 'Prochain épisode pas encore diffusé';

  @override
  String debugQuickAddNotReleasedDetail(String date) {
    return 'Diffusion le $date';
  }

  @override
  String get debugQuickAddNotReleasedUnknown => 'Date de diffusion inconnue';

  @override
  String get debugQuickAddNotPopulated => 'Non ajouté à l\'ajout rapide';

  @override
  String get debugQuickAddNotPopulatedDetail =>
      'Épisode diffusé absent de l\'ajout rapide : essayez Recalculer';

  @override
  String get debugQuickAddNoAirDate => 'Sans date de diffusion';

  @override
  String get debugQuickAddNoAirDateDetail =>
      'L\'épisode n\'a pas de date de diffusion connue';

  @override
  String get debugQuickAddNoCacheData => 'Données de saison absentes du cache';

  @override
  String get debugQuickAddNoCacheDataDetail =>
      'Touchez Recalculer pour récupérer la saison';

  @override
  String upcomingTitle(int count) {
    return 'À venir · $count';
  }

  @override
  String get upcomingGroupReleased => 'Déjà sorties';

  @override
  String get upcomingGroupThisWeek => 'Cette semaine';

  @override
  String get upcomingGroupThisMonth => 'Ce mois-ci';

  @override
  String get upcomingGroupLater => 'Plus tard';

  @override
  String upcomingGroupCount(String label, int count) {
    return '$label · $count';
  }

  @override
  String upcomingUndatedRow(int count) {
    return '$count sans date';
  }

  @override
  String get upcomingUndatedRowSubtitle =>
      'Renouvelées, prévues, épisodes à dater';

  @override
  String upcomingUndatedSection(int count) {
    return 'Sans date · $count';
  }

  @override
  String get upcomingNothingPlanned => 'Rien de prévu.';

  @override
  String upcomingDebugRow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sorties masquées',
      one: '1 sortie masquée',
      zero: '0 sortie masquée',
    );
    return 'Debug · $_temp0';
  }

  @override
  String get upcomingDebugRowSubtitle => 'Voir les raisons';

  @override
  String upcomingMarkSeen(String title) {
    return 'Marquer $title comme vu';
  }

  @override
  String upcomingSeenMessage(String title) {
    return 'Vu · $title';
  }

  @override
  String get upcomingDisableAlert => 'Désactiver l\'alerte';

  @override
  String get upcomingDisableAlertSubtitle =>
      'Le titre n\'apparaîtra plus dans À venir';

  @override
  String upcomingAlertDisabledMessage(String title) {
    return 'Alerte désactivée · $title';
  }

  @override
  String get debugHiddenReleasesTitle => 'Debug — sorties masquées';

  @override
  String get debugHiddenReleasesSubtitle =>
      'Ces éléments existent dans la base mais sont omis ci-dessus.';

  @override
  String get debugReleaseAlreadySeen => 'Déjà vu';

  @override
  String get debugReleaseAlreadySeenDetail => 'Déjà dans l\'historique';

  @override
  String debugReleaseTooOld(int days) {
    return 'Diffusé il y a plus de $days jours';
  }

  @override
  String debugReleaseTooOldDetail(String date) {
    return 'Date de diffusion enregistrée : $date';
  }

  @override
  String get debugReleaseNoDate => 'Aucune date enregistrée';

  @override
  String get listsSortOrderManual => 'Ordre manuel';

  @override
  String get listsSortOrderReleaseDate => 'Date de sortie';

  @override
  String get listsSortOrderShuffle => 'Aléatoire';

  @override
  String listsSortOrderReversed(String order) {
    return '$order inversé';
  }

  @override
  String listsHeaderSubtitle(int count, String order) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
      zero: '0 élément',
    );
    return '$_temp0 · $order';
  }

  @override
  String get listsDisplayGrid2 => 'Grille (2 colonnes)';

  @override
  String get listsDisplayGrid3 => 'Grille (3 colonnes)';

  @override
  String get listsDisplayGrid4 => 'Grille (4 colonnes)';

  @override
  String get listsDisplayDetailedList => 'Liste détaillée';

  @override
  String get listsActionShare => 'Partager la liste';

  @override
  String get listsActionSelect => 'Sélectionner';

  @override
  String get listsSelectAll => 'Tout';

  @override
  String get listsDeselectAll => 'Aucun';

  @override
  String get listsRemove => 'Retirer';

  @override
  String listsRemovedNotification(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments retirés',
      one: '1 élément retiré',
    );
    return '$_temp0';
  }

  @override
  String get listsFillBySwiping => 'Remplir en swipant';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get filtersSortBy => 'Trier par';

  @override
  String get filtersSortRelevance => 'Pertinence';

  @override
  String get filtersSortRating => 'Mieux notés';

  @override
  String get filtersSortRecent => 'Plus récents';

  @override
  String get filtersSortOldest => 'Plus anciens';

  @override
  String get filtersPeriod => 'Année de sortie';

  @override
  String get filtersPeriodAll => 'Toutes';

  @override
  String get filtersPeriodBefore1990 => 'Avant 1990';

  @override
  String get filtersPeriod1990s => '1990–1999';

  @override
  String get filtersPeriod2000s => '2000–2009';

  @override
  String get filtersPeriod2010s => '2010–2019';

  @override
  String get filtersPeriod2020plus => '2020 et après';

  @override
  String get filtersRatingTitle => 'Note minimale';

  @override
  String get filtersRatingSubtitle => 'Films et séries';

  @override
  String get filtersRatingAll => 'Toutes';

  @override
  String get filtersRating7Plus => '7+';

  @override
  String get filtersRating8Plus => '8+';

  @override
  String get filtersDurationTitle => 'Durée';

  @override
  String get filtersDurationSubtitle => 'Films uniquement';

  @override
  String get filtersDurationNotApplicable => 'Non applicable aux séries';

  @override
  String get filtersDurationAll => 'Toutes';

  @override
  String get filtersDurationUnder105 => 'Moins de 1 h 45';

  @override
  String get filtersDuration105To150 => '1 h 45 à 2 h 30';

  @override
  String get filtersDurationOver150 => 'Plus de 2 h 30';

  @override
  String get filtersHideSeen => 'Masquer ce que j\'ai déjà vu ou lu';

  @override
  String get filtersClearAll => 'Tout effacer';

  @override
  String get filtersShowResults => 'Afficher les résultats';

  @override
  String filtersShowNResults(int count) {
    return 'Afficher $count résultats';
  }

  @override
  String filtersChipSort(String sort) {
    return 'Tri : $sort';
  }

  @override
  String filtersChipRating(String rating) {
    return 'Note $rating+';
  }

  @override
  String get filtersChipHideSeen => 'Non vus';

  @override
  String get historyToday => 'Aujourd\'hui';

  @override
  String get historyYesterday => 'Hier';

  @override
  String historyDayHeaderSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
    );
    return '$_temp0';
  }

  @override
  String get historyModeChronologicalHint => 'Entrées chronologiques';

  @override
  String get historyModeLibraryHint => 'Une entrée par titre';

  @override
  String get historyActionOpenDetail => 'Ouvrir la fiche';

  @override
  String get historyActionDeleteViewing => 'Supprimer ce visionnage';

  @override
  String historyTimesSeen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vu $count fois',
      one: 'Vu 1 fois',
    );
    return '$_temp0';
  }

  @override
  String historyTvLibrarySubtitle(int episodesSeen, int entries) {
    String _temp0 = intl.Intl.pluralLogic(
      episodesSeen,
      locale: localeName,
      other: '$episodesSeen épisodes vus',
      one: '1 épisode vu',
    );
    String _temp1 = intl.Intl.pluralLogic(
      entries,
      locale: localeName,
      other: '$entries entrées',
      one: '1 entrée',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String historyEpisodeSubtitle(int season, int episode) {
    return 'S$season É$episode';
  }

  @override
  String get historySegmentHistory => 'Historique';

  @override
  String get historySegmentLibrary => 'Bibliothèque';

  @override
  String get historySortRecent => 'Date (plus récent)';

  @override
  String get historySortOldest => 'Date (plus ancien)';

  @override
  String get historySortTitleAsc => 'Nom (A–Z)';

  @override
  String get historySortTitleDesc => 'Nom (Z–A)';

  @override
  String get settingsSectionTracking => 'Suivi';

  @override
  String get settingsAdvancedTracking => 'Mode avancé';

  @override
  String get settingsAdvancedTrackingSubtitle =>
      'Saisie de la date et de l\'heure des visionnages, modification d\'entrées passées';

  @override
  String get commonMarkAsSeenWithDots => 'Marquer comme vu…';

  @override
  String get seenRewatchAction => 'Revu';

  @override
  String get seenRewatchActionWithDots => 'Revu…';

  @override
  String seenSummaryOnce(String date) {
    return 'Vu 1 fois · le $date';
  }

  @override
  String seenSummaryMultiple(int count, String date) {
    return 'Vu $count fois · dernière fois le $date';
  }

  @override
  String seenAddedMessage(String title) {
    return 'Marqué comme vu · $title';
  }

  @override
  String get seenFutureDateError =>
      'La date de visionnage ne peut pas être dans le futur';

  @override
  String seenOrdinal(String ordinal) {
    String _temp0 = intl.Intl.selectLogic(ordinal, {
      '1': '1er',
      'other': '${ordinal}e',
    });
    return '$_temp0 visionnage';
  }

  @override
  String get seenEditViewing => 'Modifier la date';

  @override
  String get seenVisionnagesSectionTitle => 'Visionnages';

  @override
  String get settingsPreviousEpisodes => 'Épisodes précédents non vus';

  @override
  String get settingsPreviousEpisodesSubtitle =>
      'Action à proposer quand des épisodes antérieurs ne sont pas vus';

  @override
  String get settingsPreviousEpisodesAsk => 'Demander';

  @override
  String get settingsPreviousEpisodesAll => 'Tous vus';

  @override
  String get settingsPreviousEpisodesOne => 'Laisser';

  @override
  String seenPreviousUnseenPrompt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count épisodes précédents ne sont pas vus. Les marquer comme vus aussi ?',
      one: '1 épisode précédent n\'est pas vu. Le marquer comme vu aussi ?',
    );
    return '$_temp0';
  }

  @override
  String get seenPreviousMarkAll => 'Oui, tout marquer vu';

  @override
  String get seenPreviousOnlyThis => 'Non, seulement cet épisode';

  @override
  String get seenRememberChoice => 'Se souvenir de mon choix';

  @override
  String seenBatchAddedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes',
      one: '1 épisode',
    );
    return 'Marqués comme vus · $_temp0';
  }

  @override
  String get detailWhereToWatch => 'Où regarder';

  @override
  String get detailWatchFlatrate => 'Abonnement';

  @override
  String get detailWatchRent => 'Location';

  @override
  String get detailWatchBuy => 'Achat';

  @override
  String get detailWatchFree => 'Gratuit';

  @override
  String get detailWatchJustWatchAttribution =>
      'Données fournies par JustWatch';

  @override
  String get settingsWatchProvidersCountry => 'Pays des plateformes';

  @override
  String get settingsWatchProvidersCountrySubtitle =>
      'Région pour les offres de streaming';

  @override
  String settingsWatchProvidersCountrySystem(String country) {
    return 'Système ($country)';
  }

  @override
  String get settingsAboutJustWatch =>
      'Données de streaming fournies par JustWatch.';

  @override
  String get personDirecting => 'Réalisation / Création';

  @override
  String get personActing => 'Interprète';

  @override
  String personSeenCount(int seen, int total) {
    return '$seen sur $total vus';
  }

  @override
  String get personOfflineNoData =>
      'Aucune information en cache pour cette personne.';

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
      other: '$seen films vus sur $total',
      one: '1 film vu sur $total',
      zero: '0 film vu sur $total',
    );
    return '$_temp0';
  }

  @override
  String get sagaCurrentItem => 'Cette fiche';

  @override
  String get sagaUpcoming => 'À venir';

  @override
  String sagaUpcomingWithYear(String year) {
    return 'À venir ($year)';
  }

  @override
  String sagaAddMissing(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ajouter $count films manquants à « $list »',
      one: 'Ajouter 1 film manquant à « $list »',
    );
    return '$_temp0';
  }

  @override
  String sagaMissingAdded(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count films ajoutés à « $list »',
      one: '1 film ajouté à « $list »',
    );
    return '$_temp0';
  }

  @override
  String detailSeasonEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes',
      one: '1 épisode',
    );
    return '$_temp0';
  }

  @override
  String detailSeasonSeenShort(int seen, int total) {
    return '$seen/$total vus';
  }

  @override
  String get togetherSessionSetup => 'Préparer la séance';

  @override
  String get togetherWeAreChoosing => 'Nous choisissons';

  @override
  String get togetherChoiceAny => 'Film ou série';

  @override
  String get togetherChoiceMovie => 'Un film';

  @override
  String get togetherChoiceTv => 'Une série';

  @override
  String get togetherMyListLabel => 'Ma liste :';

  @override
  String get togetherWarningNotice =>
      'Le QR contient votre liste : ceux qui le scannent la voient.';

  @override
  String get togetherScanQrButton => 'Scanner le QR d\'un ami';

  @override
  String get togetherParticipantsTitle => 'Participants';

  @override
  String get togetherYouHost => 'Moi (Hôte)';

  @override
  String get togetherFriendName => 'Ami';

  @override
  String togetherItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
      zero: '0 titre',
    );
    return '$_temp0';
  }

  @override
  String get togetherScanPrompt => 'Scannez au moins un ami pour continuer';

  @override
  String get togetherSeeCommonTitles => 'Voir les titres en commun';

  @override
  String togetherCommonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en commun',
      one: '1 titre en commun',
      zero: 'Aucun titre en commun',
    );
    return '$_temp0';
  }

  @override
  String togetherAlmostSection(int k, int n) {
    return 'Presque : dans $k listes sur $n';
  }

  @override
  String togetherVoteLimitNotice(int count) {
    return 'Le vote porte sur les 6 titres les mieux notés (sur $count)';
  }

  @override
  String get togetherEmptyCommonTitle => 'Aucun titre en commun';

  @override
  String get togetherEmptyCommonMessage =>
      'Aucun de vos titres ne correspond sur toutes les listes. Regardez la section « Presque » ci-dessous !';

  @override
  String get togetherRandomPick => 'Tirage au sort';

  @override
  String get togetherSwipeVote => 'Voter en swipant';

  @override
  String get togetherWatchThis => 'On le regarde !';

  @override
  String get togetherResetSession => 'Réinitialiser la séance';

  @override
  String get togetherResetConfirm =>
      'Réinitialiser cette séance et effacer tous les participants scannés ?';

  @override
  String get togetherHideSeen => 'Masquer les vus';

  @override
  String togetherMultiQrPart(int current, int total) {
    return 'Partie $current sur $total';
  }

  @override
  String togetherScanNextPart(int current, int total) {
    return 'Scannez la partie suivante ($current/$total)';
  }

  @override
  String get togetherLeaveVoteTitle => 'Quitter le vote';

  @override
  String get togetherLeaveVoteConfirm =>
      'Les votes déjà donnés seront perdus. Les participants restent dans la séance.';

  @override
  String get togetherLeaveVoteButton => 'Quitter';

  @override
  String get togetherYourTurn => 'À vous de voter';

  @override
  String get togetherHostStartVote => 'Je vote';

  @override
  String togetherPassPhone(String name) {
    return 'Passez le téléphone à $name';
  }

  @override
  String get togetherParticipantStartVote => 'C\'est parti !';

  @override
  String togetherVoteProgress(int current, int total) {
    return 'Titre $current sur $total';
  }

  @override
  String get togetherVoteYes => 'Oui';

  @override
  String get togetherVoteNo => 'Non';

  @override
  String get togetherTonightChoice => 'Le choix du soir';

  @override
  String get togetherUnanimousVote => 'Unanimité !';

  @override
  String togetherVoteCountFraction(int count, int total) {
    return '$count votes sur $total';
  }

  @override
  String get togetherTieBadge => 'Égalité';

  @override
  String get togetherOtherTitles => 'Autres titres';

  @override
  String get togetherReviewList => 'Revoir la liste';

  @override
  String togetherWatchingToast(String title) {
    return 'Bon visionnage de $title !';
  }

  @override
  String swiperDiscardedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres écartés',
      one: '1 titre écarté',
      zero: 'Aucun titre écarté',
    );
    return '$_temp0';
  }

  @override
  String get swiperResetButton => 'Réinitialiser';

  @override
  String get swiperResetConfirmTitle => 'Réinitialiser les choix de swipe ?';

  @override
  String get swiperResetConfirmMessage =>
      'Les titres que vous aviez écartés pourront réapparaître dans le mode swipe. Les succès déjà obtenus sont conservés.';

  @override
  String get swiperResetSuccessToast => 'Choix de swipe réinitialisés';

  @override
  String get settingsAboutTmdb =>
      'Ce produit utilise l\'API TMDB mais n\'est ni approuvé ni certifié par TMDB.';

  @override
  String get listsMoveOrCopy => 'Déplacer ou copier vers une autre liste';

  @override
  String get listsMoveOrCopyTitle => 'Déplacer ou copier vers…';

  @override
  String get listsActionMove => 'Déplacer';

  @override
  String get listsActionCopy => 'Copier';

  @override
  String listsMovedNotification(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments déplacés vers $list',
      one: '1 élément déplacé vers $list',
    );
    return '$_temp0';
  }

  @override
  String listsCopiedNotification(int count, String list) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments copiés vers $list',
      one: '1 élément copié vers $list',
    );
    return '$_temp0';
  }
}
