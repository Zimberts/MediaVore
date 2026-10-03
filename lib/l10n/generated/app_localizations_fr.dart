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
}
