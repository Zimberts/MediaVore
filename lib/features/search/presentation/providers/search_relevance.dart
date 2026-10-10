import 'package:mediavore/core/domain/entities/media_item.dart';

/// Scores how well [title] matches [query] (4 exact, 3 prefix, 2 substring,
/// 1 shared word, 0 otherwise).
int titleSimilarityScore(String query, String title) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return 0;
  final normalizedTitle = title.trim().toLowerCase();
  if (normalizedTitle == normalizedQuery) return 4;
  if (normalizedTitle.startsWith(normalizedQuery)) return 3;
  if (normalizedTitle.contains(normalizedQuery)) return 2;
  final queryWords = normalizedQuery
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toSet();
  if (queryWords.isEmpty) return 0;
  final titleWords = normalizedTitle
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toSet();
  final overlap = queryWords.intersection(titleWords).length;
  return overlap > 0 ? 1 : 0;
}

/// Sorts [items] in place by title similarity to [query], then by rating.
void sortMediaByRelevance(List<MediaItem> items, String query) {
  items.sort((a, b) {
    final scoreA = titleSimilarityScore(query, a.title);
    final scoreB = titleSimilarityScore(query, b.title);
    if (scoreA != scoreB) return scoreB.compareTo(scoreA);
    final ratingA = a.voteAverage ?? 0;
    final ratingB = b.voteAverage ?? 0;
    return ratingB.compareTo(ratingA);
  });
}
