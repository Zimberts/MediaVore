import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/saga_sort.dart';
import 'package:mediavore/core/widgets/app_message.dart';
import 'package:mediavore/features/library/presentation/widgets/lists_overview.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

/// Horizontal row displaying the saga (collection) of [currentItem].
///
/// Shows « Saga · {name} », seen counter « n films vus sur m », the movies in
/// chronological order (with index, seen badge, "This title" overlay, "Upcoming"
/// overlay), and an action button to add missing movies to the target list.
class MediaDetailSaga extends StatelessWidget {
  const MediaDetailSaga({
    super.key,
    required this.currentItem,
    required this.collection,
    required this.seenStatus,
    required this.onOpen,
  });

  final MediaItem currentItem;
  final List<MediaItem>? collection;
  final List<SeenItem> seenStatus;
  final ValueChanged<MediaItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final collection = this.collection;
    if (collection == null || collection.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = sortSagaByDate(collection);
    if (sorted.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);
    final searchProvider = context.watch<SearchProvider>();

    final totalCount = sorted.length;
    final seenCount = sorted
        .where((item) => seenStatus.any((s) => s.tmdbId == item.id))
        .length;

    // Resolve target list: current film's list or first available list (watchlist).
    final targetList = searchProvider.listNames.firstWhere(
      (name) => searchProvider.isItemInList(currentItem, name),
      orElse: () => searchProvider.listNames.firstOrNull ?? 'watchlist',
    );

    // Missing films: neither seen nor already present in target list.
    final missingFilms = sorted.where((item) {
      final isSeen = seenStatus.any((s) => s.tmdbId == item.id);
      final inList = searchProvider.isItemInList(item, targetList);
      return !isSeen && !inList;
    }).toList();

    final sagaName = currentItem.collectionName?.trim();
    final headerTitle = (sagaName != null && sagaName.isNotEmpty)
        ? l10n.sagaHeader(sagaName)
        : l10n.sagaHeaderDefault;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                headerTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.sagaSeenCount(seenCount, totalCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.text2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = sorted[index];
              return _SagaFilmCard(
                item: item,
                index: index + 1,
                isCurrent: item.id == currentItem.id,
                isSeen: seenStatus.any((s) => s.tmdbId == item.id),
                onTap: item.id == currentItem.id ? null : () => onOpen(item),
              );
            },
          ),
        ),
        if (missingFilms.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () async {
                await searchProvider.addAllToList(missingFilms, targetList);
                if (context.mounted) {
                  showAppMessage(
                    l10n.sagaMissingAdded(
                      missingFilms.length,
                      listDisplayName(l10n, targetList),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.playlist_add),
              label: Text(
                l10n.sagaAddMissing(
                  missingFilms.length,
                  listDisplayName(l10n, targetList),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SagaFilmCard extends StatelessWidget {
  const _SagaFilmCard({
    required this.item,
    required this.index,
    required this.isCurrent,
    required this.isSeen,
    required this.onTap,
  });

  final MediaItem item;
  final int index;
  final bool isCurrent;
  final bool isSeen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final theme = Theme.of(context);

    final releaseDate = DateTime.tryParse(item.releaseDate);
    final isUpcoming = item.releaseDate.isEmpty ||
        (releaseDate != null && releaseDate.isAfter(DateTime.now()));

    final year = item.releaseDate.length >= 4
        ? item.releaseDate.substring(0, 4)
        : '';

    return Semantics(
      button: onTap != null,
      label: isCurrent ? '${item.title} (${l10n.sagaCurrentItem})' : item.title,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 155,
                  decoration: BoxDecoration(
                    color: colors.placeholder,
                    border: isCurrent
                        ? Border.all(color: colors.primary, width: 2)
                        : null,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.posterPath != null &&
                          !Platform.environment.containsKey('FLUTTER_TEST'))
                        CachedNetworkImage(
                          imageUrl:
                              'https://image.tmdb.org/t/p/w185${item.posterPath}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Container(color: colors.placeholder),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.movie),
                        )
                      else
                        Center(
                          child: Icon(
                            Icons.movie,
                            color: colors.text2.withValues(alpha: 0.5),
                          ),
                        ),
                      // Number badge on top-left
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$index',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Seen checkmark on top-right
                      if (isSeen)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: colors.success,
                              size: 18,
                            ),
                          ),
                        ),
                      // "Cette fiche" bottom banner
                      if (isCurrent)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            color: colors.primary,
                            child: Text(
                              l10n.sagaCurrentItem,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (isUpcoming)
                        // "À venir" bottom banner
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            color: Colors.black.withValues(alpha: 0.75),
                            child: Text(
                              year.isNotEmpty
                                  ? l10n.sagaUpcomingWithYear(year)
                                  : l10n.sagaUpcoming,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (year.isNotEmpty)
                Text(
                  year,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.text2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
