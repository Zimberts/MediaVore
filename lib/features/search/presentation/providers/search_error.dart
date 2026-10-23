import 'package:mediavore/core/error/exceptions.dart';
import 'package:mediavore/core/l10n/l10n.dart';
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

/// User-facing message for a [SearchErrorType], in English unless [l10n]
/// is given.
String searchErrorMessage(SearchErrorType type, [AppLocalizations? l10n]) {
  final strings = l10n ?? fallbackLocalizations;
  switch (type) {
    case SearchErrorType.missingApiKey:
      return strings.searchErrorMissingApiKey;
    case SearchErrorType.invalidApiKey:
      return strings.searchErrorInvalidApiKey;
    case SearchErrorType.offline:
      return strings.searchErrorOffline;
    case SearchErrorType.server:
      return strings.searchErrorServer;
    case SearchErrorType.unknown:
      return strings.searchErrorUnknown;
  }
}
