import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/search/domain/entities/search_filters.dart';

/// Horizontal scrollable bar displaying active [SearchFilters] as removable chips.
class ActiveFilterChips extends StatelessWidget {
  final SearchFilters filters;
  final ValueChanged<SearchFilters> onFilterChanged;
  final VoidCallback onClearAll;

  const ActiveFilterChips({
    super.key,
    required this.filters,
    required this.onFilterChanged,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (filters.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final chips = <Widget>[];

    // Media Type Chip
    if (filters.type != null) {
      final label = filters.type == MediaType.movie
          ? l10n.commonMovies
          : l10n.commonTvShows;
      chips.add(
        InputChip(
          label: Text(label),
          onDeleted: () => onFilterChanged(filters.copyWith(type: () => null)),
        ),
      );
    }

    // Sort Chip
    if (filters.sort != SearchSort.relevance) {
      final String sortLabel;
      switch (filters.sort) {
        case SearchSort.rating:
          sortLabel = l10n.filtersSortRating;
          break;
        case SearchSort.releaseDateDesc:
          sortLabel = l10n.filtersSortRecent;
          break;
        case SearchSort.releaseDateAsc:
          sortLabel = l10n.filtersSortOldest;
          break;
        case SearchSort.relevance:
          sortLabel = l10n.filtersSortRelevance;
          break;
      }
      chips.add(
        InputChip(
          label: Text(l10n.filtersChipSort(sortLabel)),
          onDeleted: () =>
              onFilterChanged(filters.copyWith(sort: SearchSort.relevance)),
        ),
      );
    }

    // Period / Year Chip
    if (filters.exactYear != null) {
      chips.add(
        InputChip(
          label: Text('${filters.exactYear}'),
          onDeleted: () =>
              onFilterChanged(filters.copyWith(exactYear: () => null)),
        ),
      );
    } else if (filters.period != SearchReleasePeriod.all) {
      final String periodLabel;
      switch (filters.period) {
        case SearchReleasePeriod.before1990:
          periodLabel = l10n.filtersPeriodBefore1990;
          break;
        case SearchReleasePeriod.d1990s:
          periodLabel = l10n.filtersPeriod1990s;
          break;
        case SearchReleasePeriod.d2000s:
          periodLabel = l10n.filtersPeriod2000s;
          break;
        case SearchReleasePeriod.d2010s:
          periodLabel = l10n.filtersPeriod2010s;
          break;
        case SearchReleasePeriod.d2020plus:
          periodLabel = l10n.filtersPeriod2020plus;
          break;
        case SearchReleasePeriod.all:
          periodLabel = l10n.filtersPeriodAll;
          break;
      }
      chips.add(
        InputChip(
          label: Text(periodLabel),
          onDeleted: () =>
              onFilterChanged(filters.copyWith(period: SearchReleasePeriod.all)),
        ),
      );
    }

    // Genre Chips
    final sortedGenreIds = filters.genreIds.toList()..sort();
    for (final genreId in sortedGenreIds) {
      chips.add(
        InputChip(
          label: Text(GenreUtils.localizedName(l10n, genreId)),
          onDeleted: () {
            final newGenres = Set<int>.from(filters.genreIds)..remove(genreId);
            onFilterChanged(filters.copyWith(genreIds: newGenres));
          },
        ),
      );
    }

    // Rating Chip
    if (filters.minRating != null) {
      chips.add(
        InputChip(
          label: Text(l10n.filtersChipRating('${filters.minRating!.toInt()}')),
          onDeleted: () =>
              onFilterChanged(filters.copyWith(minRating: () => null)),
        ),
      );
    }

    // Duration Chip
    if (filters.duration != MovieDuration.all) {
      final String durationLabel;
      switch (filters.duration) {
        case MovieDuration.under105:
          durationLabel = l10n.filtersDurationUnder105;
          break;
        case MovieDuration.between105And150:
          durationLabel = l10n.filtersDuration105To150;
          break;
        case MovieDuration.over150:
          durationLabel = l10n.filtersDurationOver150;
          break;
        case MovieDuration.all:
          durationLabel = l10n.filtersDurationAll;
          break;
      }
      chips.add(
        InputChip(
          label: Text(durationLabel),
          onDeleted: () =>
              onFilterChanged(filters.copyWith(duration: MovieDuration.all)),
        ),
      );
    }

    // Hide Seen Chip
    if (filters.hideSeen) {
      chips.add(
        InputChip(
          label: Text(l10n.filtersChipHideSeen),
          onDeleted: () => onFilterChanged(filters.copyWith(hideSeen: false)),
        ),
      );
    }

    // Clear all action chip
    chips.add(
      ActionChip(
        avatar: Icon(
          Icons.clear_all,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        label: Text(
          l10n.filtersClearAll,
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        onPressed: onClearAll,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips
              .map(
                (c) =>
                    Padding(padding: const EdgeInsets.only(right: 8), child: c),
              )
              .toList(),
        ),
      ),
    );
  }
}
