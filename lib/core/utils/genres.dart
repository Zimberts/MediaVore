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

  static Map<int, String> getAllGenres() {
    return {...movieGenres, ...tvGenres};
  }

  /// Genre names as returned by TMDB (English and French) when they differ
  /// from the display names above. Keys are lowercase.
  static const Map<String, int> _aliases = {
    'science fiction': 878,
    'tv movie': 10770,
    'aventure': 12,
    'comédie': 35,
    'documentaire': 99,
    'drame': 18,
    'familial': 10751,
    'fantastique': 14,
    'histoire': 36,
    'horreur': 27,
    'musique': 10402,
    'mystère': 9648,
    'science-fiction': 878,
    'téléfilm': 10770,
    'guerre': 10752,
    'science-fiction & fantastique': 10765,
    'guerre & politique': 10768,
    'enfants': 10762,
    'actualités': 10763,
    'téléréalité': 10764,
    'feuilleton': 10766,
  };

  static int? getGenreIdByName(String name) {
    final lower = name.trim().toLowerCase();
    final all = getAllGenres();
    for (final entry in all.entries) {
      if (entry.value.toLowerCase() == lower) {
        return entry.key;
      }
    }
    // Fallback for TMDB names (English or French) that differ from the
    // display names, so localized genres stored on seen items still resolve.
    return _aliases[lower];
  }
}
