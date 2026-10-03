import 'package:mediavore/core/l10n/app_language.dart';
import 'package:mediavore/l10n/generated/app_localizations.dart';

class GenreUtils {
  static const Map<int, String> movieGenres = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
  };

  static const Map<int, String> tvGenres = {
    10759: 'Action & Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    10762: 'Kids',
    9648: 'Mystery',
    10763: 'News',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Soap',
    10767: 'Talk',
    10768: 'War & Politics',
    37: 'Western',
  };

  /// TMDB genre names that differ from the ARB ones (TMDB `/genre/*/list`).
  static const Map<String, int> _tmdbAliases = {
    'science fiction': 878,
    'science-fiction': 878,
    'science-fiction & fantastique': 10765,
  };

  static Map<int, String> getAllGenres() {
    return {...movieGenres, ...tvGenres};
  }

  /// Name of genre [id] in [l10n]'s language, or the English one.
  static String localizedName(AppLocalizations l10n, int id) {
    switch (id) {
      case 28:
        return l10n.genreAction;
      case 12:
        return l10n.genreAdventure;
      case 16:
        return l10n.genreAnimation;
      case 35:
        return l10n.genreComedy;
      case 80:
        return l10n.genreCrime;
      case 99:
        return l10n.genreDocumentary;
      case 18:
        return l10n.genreDrama;
      case 10751:
        return l10n.genreFamily;
      case 14:
        return l10n.genreFantasy;
      case 36:
        return l10n.genreHistory;
      case 27:
        return l10n.genreHorror;
      case 10402:
        return l10n.genreMusic;
      case 9648:
        return l10n.genreMystery;
      case 10749:
        return l10n.genreRomance;
      case 878:
        return l10n.genreSciFi;
      case 10770:
        return l10n.genreTvMovie;
      case 53:
        return l10n.genreThriller;
      case 10752:
        return l10n.genreWar;
      case 37:
        return l10n.genreWestern;
      case 10759:
        return l10n.genreActionAdventure;
      case 10762:
        return l10n.genreKids;
      case 10763:
        return l10n.genreNews;
      case 10764:
        return l10n.genreReality;
      case 10765:
        return l10n.genreSciFiFantasy;
      case 10766:
        return l10n.genreSoap;
      case 10767:
        return l10n.genreTalk;
      case 10768:
        return l10n.genreWarPolitics;
    }
    return getAllGenres()[id] ?? '';
  }

  /// Resolves a genre name in any supported language (TMDB returns names in
  /// the app language) to its TMDB id.
  static int? getGenreIdByName(String name) {
    final needle = name.toLowerCase();
    if (_idCache.containsKey(needle)) return _idCache[needle];
    return _idCache[needle] = _findGenreId(needle);
  }

  static final Map<String, int?> _idCache = {};

  static int? _findGenreId(String needle) {
    final alias = _tmdbAliases[needle];
    if (alias != null) return alias;
    final ids = getAllGenres().keys;
    for (final id in ids) {
      if (getAllGenres()[id]!.toLowerCase() == needle) return id;
    }
    for (final language in supportedAppLanguages) {
      final l10n = lookupAppLocalizations(language.locale);
      for (final id in ids) {
        if (localizedName(l10n, id).toLowerCase() == needle) return id;
      }
    }
    return null;
  }
}
