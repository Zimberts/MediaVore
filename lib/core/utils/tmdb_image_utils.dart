/// Supported TMDB image widths/resolutions.
enum TmdbImageSize {
  w92('w92'),
  w154('w154'),
  w185('w185'),
  w342('w342'),
  w500('w500'),
  w780('w780'),
  original('original');

  const TmdbImageSize(this.value);

  /// Suffix string used in TMDB image paths (e.g. 'w185').
  final String value;

  /// Resolves [size] string to a [TmdbImageSize] enum value, falling back
  /// to [fallback] (defaulting to [TmdbImageSize.w185]).
  static TmdbImageSize fromString(
    String? size, {
    TmdbImageSize fallback = TmdbImageSize.w185,
  }) {
    if (size == null || size.isEmpty) return fallback;
    for (final candidate in TmdbImageSize.values) {
      if (candidate.value == size) return candidate;
    }
    return fallback;
  }
}

/// Centralized utility for constructing TMDB image URLs.
abstract final class TmdbImageUtils {
  /// Base URL of the TMDB image CDN.
  static const String baseUrl = 'https://image.tmdb.org/t/p';

  /// Constructs a full TMDB image URL from a relative image [path] and [size].
  ///
  /// Returns `null` if [path] is `null` or whitespace-only.
  /// Automatically ensures [path] has a leading slash.
  static String? buildUrl(
    String? path, {
    TmdbImageSize size = TmdbImageSize.w185,
  }) {
    if (path == null) return null;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$baseUrl/${size.value}$normalized';
  }

  /// Helper to construct a TMDB image URL when the size is given as a string.
  static String? buildUrlWithSizeString(
    String? path, {
    String? size,
    TmdbImageSize fallback = TmdbImageSize.w185,
  }) {
    return buildUrl(
      path,
      size: TmdbImageSize.fromString(size, fallback: fallback),
    );
  }
}

/// Extension on nullable [String] paths for fluent TMDB URL resolution.
extension TmdbImagePathX on String? {
  /// Returns the full TMDB image URL for this path, or `null` if null/empty.
  String? tmdbImageUrl([TmdbImageSize size = TmdbImageSize.w185]) =>
      TmdbImageUtils.buildUrl(this, size: size);
}
