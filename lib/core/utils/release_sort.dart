import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/features/search/domain/repositories/media_repository.dart';

int releaseGroupPriority(NotifiedItem item) {
  if (item.releaseDate != null) return 0;
  if (item.type == MediaType.tv &&
      item.seasonNumber != null &&
      item.episodeNumber != null) {
    return 1;
  }
  if (item.type == MediaType.tv) return 2;
  return 3;
}

List<NotifiedItem> sortReleases(List<NotifiedItem> items) {
  final sorted = [...items];
  sorted.sort((a, b) {
    final priorityA = releaseGroupPriority(a);
    final priorityB = releaseGroupPriority(b);

    if (priorityA != priorityB) {
      return priorityA.compareTo(priorityB);
    }

    if (priorityA == 0 && a.releaseDate != null && b.releaseDate != null) {
      return a.releaseDate!.compareTo(b.releaseDate!);
    }

    return a.title.compareTo(b.title);
  });

  return sorted;
}

/// Subtitle for a release without a date, in English unless [l10n] is given.
String releaseSubtitleForItem(NotifiedItem item, [AppLocalizations? l10n]) {
  final strings = l10n ?? fallbackLocalizations;
  if (item.releaseDate != null) {
    return '';
  }

  if (item.type == MediaType.tv &&
      item.seasonNumber != null &&
      item.episodeNumber != null) {
    return strings.releaseEpisodeTba;
  }

  if (item.type == MediaType.tv) {
    return strings.releaseReturning;
  }

  return strings.releasePlanned;
}