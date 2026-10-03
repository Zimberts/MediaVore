import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

/// Why the last search/discover request failed, so the UI can react to it.
enum SearchErrorType { missingApiKey, invalidApiKey, offline, server, unknown }

/// Maps an error thrown by [MediaRepository.searchMedia] / `discoverMedia`
/// to a [SearchErrorType].
SearchErrorType classifySearchError(Object error) {
  if (error is ConfigurationException) return SearchErrorType.missingApiKey;
  if (error is NetworkException) return SearchErrorType.offline;
  if (error is ServerException) {
    final code = error.statusCode;
    if (code == 401 || code == 403) return SearchErrorType.invalidApiKey;
    return SearchErrorType.server;
  }
  return SearchErrorType.unknown;
}

/// User-facing message for a [SearchErrorType].
String searchErrorMessage(SearchErrorType type) {
  switch (type) {
    case SearchErrorType.missingApiKey:
      return 'Add your TMDB API key in Settings to search and discover media.';
    case SearchErrorType.invalidApiKey:
      return 'Your TMDB API key was rejected. Check it in Settings.';
    case SearchErrorType.offline:
      return "You're offline. Check your connection and try again.";
    case SearchErrorType.server:
      return 'TMDB is unavailable right now. Please try again later.';
    case SearchErrorType.unknown:
      return 'Something went wrong while loading results.';
  }
}
