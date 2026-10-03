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
  String appStartupFailed(String error) {
    return 'Échec du démarrage de l\'application :\n$error';
  }

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonImport => 'Importer';

  @override
  String get commonOpenSettings => 'Ouvrir les paramètres';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navMyLists => 'Mes listes';

  @override
  String get navSeen => 'Vus';

  @override
  String get navAlerts => 'Alertes';

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
  String get tmdbCredentialRequiredTitle => 'Identifiant TMDB requis';

  @override
  String get tmdbCredentialRequiredMessage =>
      'Pour utiliser cette application, il vous faut un identifiant TMDB (clé d\'API v3 ou jeton de lecture v4). Vous pouvez en obtenir un sur themoviedb.org.';

  @override
  String get tmdbCredentialHint => 'Clé d\'API TMDB v3 ou jeton de lecture v4';

  @override
  String get tmdbCredentialLater =>
      'Vous pourrez définir votre clé d\'API plus tard dans les paramètres (accessibles depuis les onglets Mes listes, Vus ou Alertes).';

  @override
  String get tmdbCredentialCancelForNow => 'Plus tard';

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
  String get settingsSectionMilestones => 'Jeu et étapes';

  @override
  String get settingsAchievements => 'Succès';

  @override
  String get settingsAchievementsSubtitle =>
      'Consultez vos badges et votre progression.';

  @override
  String get settingsSectionListsDisplay => 'Affichage des listes';

  @override
  String get settingsHideNonReleased => 'Masquer les contenus non sortis';

  @override
  String get settingsHideNonReleasedSubtitle =>
      'N\'afficher que les films et épisodes déjà diffusés.';

  @override
  String get settingsSectionStorage => 'Stockage et historique';

  @override
  String get settingsStorage => 'Stockage et données';

  @override
  String get settingsStorageSubtitle =>
      'Gérer le cache, les exports et la base de l\'historique.';

  @override
  String get settingsSectionApi => 'Configuration de l\'API';

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
  String get dataRefetchRuntimes => 'Récupérer les durées';

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
  ) {
    return 'Ce fichier contient :\nVus : $seen\nFavoris : $likes\nNotifications : $notifications\nListes : $lists\n\nChoisissez comment appliquer ces données à votre profil.';
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
  String get listsGridSize => 'Taille de la grille';

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
  String get listsShowQr => 'Afficher le QR code';

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
  String get listsCouldNotParseLink => 'Impossible de lire le lien';

  @override
  String get listsConfirmImport => 'Confirmer l\'import';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get listsSortOptions => 'Options de tri';

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
    );
    return '$_temp0';
  }

  @override
  String get listsWatchlist => 'À voir';

  @override
  String get listsRemoveSelected => 'Retirer la sélection';

  @override
  String get listsDisplayMode => 'Mode d\'affichage';

  @override
  String get listsEmpty => 'Aucun élément dans cette liste.';

  @override
  String get listsSwitchList => 'Changer de liste';

  @override
  String listsItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
      zero: '0 élément',
    );
    return '$_temp0';
  }

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
  String mediaSeasonShort(String count) {
    return '$count S';
  }

  @override
  String get seenRemoveLogTitle => 'Supprimer l\'entrée ?';

  @override
  String get seenRemoveLogMessage =>
      'Voulez-vous vraiment retirer ce visionnage de votre historique ?';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get seenFilterSort => 'Filtrer et trier';

  @override
  String get seenViewMode => 'Mode d\'affichage';

  @override
  String get seenViewHistory => 'Historique (tous les épisodes)';

  @override
  String get seenViewLibrary => 'Bibliothèque (titres uniques)';

  @override
  String get seenSortBy => 'Trier par';

  @override
  String get seenSortDateNewest => 'Date (plus récent)';

  @override
  String get seenSortDateOldest => 'Date (plus ancien)';

  @override
  String get seenSortNameAsc => 'Nom (A-Z)';

  @override
  String get seenSortNameDesc => 'Nom (Z-A)';

  @override
  String get seenMediaType => 'Type de média';

  @override
  String get commonAll => 'Tous';

  @override
  String get commonMovies => 'Films';

  @override
  String get commonTvShows => 'Séries';

  @override
  String get seenTitle => 'Historique';

  @override
  String get seenSearchHint => 'Rechercher dans l\'historique...';

  @override
  String get seenStatistics => 'Statistiques';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get seenEmpty => 'Rien de vu pour l\'instant.';

  @override
  String get seenNoMatches => 'Aucun résultat.';

  @override
  String seenEpisodesSeen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count épisodes vus',
      one: '1 épisode vu',
      zero: '0 épisode vu',
    );
    return '$_temp0';
  }

  @override
  String get seenCannotDeleteLibrary =>
      'Impossible de supprimer en mode Bibliothèque. Passez en mode Historique pour retirer des entrées.';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get statsEmpty => 'Pas encore de données. À vos écrans !';

  @override
  String get statsToggleMetric => 'Changer d\'indicateur (entrées/durée)';

  @override
  String get statsAllTime => 'Depuis toujours';

  @override
  String get statsYear => 'Année';

  @override
  String get statsMonth => 'Mois';

  @override
  String get statsOverview => 'Aperçu';

  @override
  String get statsDistribution => 'Répartition';

  @override
  String get statsSelectYear => 'Choisir l\'année';

  @override
  String get statsSelectPeriod => 'Choisir la période';

  @override
  String get statsTotalWatchTime => 'Temps de visionnage total';

  @override
  String statsDuration(int days, int hours, int minutes) {
    return '$days j $hours h $minutes min';
  }

  @override
  String get statsEpisodes => 'Épisodes';

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
  String statsPieLabel(String type, String percent) {
    return '$type\n$percent %';
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
  String get discoveryReleaseYear => 'Année de sortie';

  @override
  String get discoveryAnyYear => 'Toutes';

  @override
  String discoveryMinRating(String rating) {
    return 'Note minimale : $rating';
  }

  @override
  String get discoveryGenres => 'Genres';

  @override
  String get discoveryReset => 'Réinitialiser';

  @override
  String get discoveryApply => 'Appliquer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get discoverySearchHint => 'Rechercher...';

  @override
  String get discoveryTitle => 'Découvrir';

  @override
  String get discoveryNoResults => 'Aucun résultat';

  @override
  String get discoveryClearFilters => 'Effacer les filtres';

  @override
  String get releaseEpisodeTba => 'Épisode — date à venir';

  @override
  String get releaseReturning => 'Renouvelée — nouvelle saison prévue';

  @override
  String get releasePlanned => 'Prévu — pas de date de sortie';

  @override
  String get notifTitle => 'Centre de notifications';

  @override
  String get notifForceRefresh => 'Forcer l\'actualisation';

  @override
  String get notifTabReleases => 'Sorties';

  @override
  String get notifTabQuickAdd => 'Ajout rapide';

  @override
  String get notifSyncing => 'Synchronisation des sorties...';

  @override
  String get notifNoReleases => 'Aucune sortie à venir ou récente.';

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
  String notifMarkedAsSeen(String title) {
    return '« $title » marqué comme vu';
  }

  @override
  String get notifNoNextEpisodes => 'Aucun prochain épisode à suivre.';

  @override
  String get commonUnknown => 'Inconnu';

  @override
  String notifNextEpisode(int season, int episode) {
    return 'Suivant : saison $season, épisode $episode';
  }

  @override
  String get notifStreakOptedOut => 'Série retirée de l\'ajout rapide';

  @override
  String get commonUndo => 'Annuler';

  @override
  String get notifEpisode => 'l\'épisode';

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
  String get detailCreator => 'Création';

  @override
  String get detailDirector => 'Réalisation';

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
  String detailCreditLine(String role, String name) {
    return '$role : $name';
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
  String get detailWatchOn => 'Disponible sur :';

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
  String get seenOpenHistory => 'Voir l\'historique';

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
  String get seenViewingHistory => 'Historique de visionnage';

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
  String achievementsUnlockedCount(int unlocked, int total) {
    return 'Vous avez débloqué $unlocked badges sur $total';
  }

  @override
  String achievementsUnlockedOn(String date) {
    return 'Débloqué le $date';
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
  String get progressRefetchDone => 'Récupération terminée !';

  @override
  String progressProcessingItem(String title) {
    return 'Traitement de $title...';
  }

  @override
  String get progressSavingEntries => 'Enregistrement des entrées...';

  @override
  String get progressImportComplete => 'Import terminé';
}
