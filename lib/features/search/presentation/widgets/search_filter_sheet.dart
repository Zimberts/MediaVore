import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/search/domain/entities/search_filters.dart';

/// Modal bottom sheet allowing the user to view and adjust [SearchFilters].
class SearchFilterSheet extends StatefulWidget {
  final SearchFilters initialFilters;
  final ValueChanged<SearchFilters> onApply;
  final int? resultCount;

  const SearchFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
    this.resultCount,
  });

  /// Displays the filter bottom sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required SearchFilters initialFilters,
    required ValueChanged<SearchFilters> onApply,
    int? resultCount,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SearchFilterSheet(
        initialFilters: initialFilters,
        onApply: onApply,
        resultCount: resultCount,
      ),
    );
  }

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchFilters _currentFilters;

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle and Header
            _buildHeader(theme, l10n),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  _buildTypeSection(theme, l10n),
                  const SizedBox(height: 16),
                  _buildSortSection(theme, l10n),
                  const SizedBox(height: 16),
                  _buildPeriodSection(theme, l10n),
                  const SizedBox(height: 16),
                  _buildGenresSection(theme, l10n),
                  const SizedBox(height: 16),
                  _buildRatingSection(theme, l10n),
                  const SizedBox(height: 16),
                  _buildDurationSection(theme, l10n),
                  const SizedBox(height: 16),
                  _buildHideSeenSection(theme, l10n),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Bottom Actions Bar
            const Divider(height: 1),
            _buildBottomBar(theme, l10n),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                l10n.filtersTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.commonClose,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSection(ThemeData theme, dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.seenMediaType,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.discoveryBoth),
              selected: _currentFilters.type == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      type: () => null,
                      genreIds: {},
                    );
                  });
                }
              },
            ),
            ChoiceChip(
              label: Text(l10n.commonMovies),
              selected: _currentFilters.type == MediaType.movie,
              onSelected: (selected) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(
                    type: () => selected ? MediaType.movie : null,
                    genreIds: {},
                  );
                });
              },
            ),
            ChoiceChip(
              label: Text(l10n.commonTvShows),
              selected: _currentFilters.type == MediaType.tv,
              onSelected: (selected) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(
                    type: () => selected ? MediaType.tv : null,
                    genreIds: {},
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortSection(ThemeData theme, dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.filtersSortBy,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.filtersSortRelevance),
              selected: _currentFilters.sort == SearchSort.relevance,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      sort: SearchSort.relevance,
                    );
                  });
                }
              },
            ),
            ChoiceChip(
              label: Text(l10n.filtersSortRating),
              selected: _currentFilters.sort == SearchSort.rating,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      sort: SearchSort.rating,
                    );
                  });
                }
              },
            ),
            ChoiceChip(
              label: Text(l10n.filtersSortRecent),
              selected: _currentFilters.sort == SearchSort.releaseDateDesc,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      sort: SearchSort.releaseDateDesc,
                    );
                  });
                }
              },
            ),
            ChoiceChip(
              label: Text(l10n.filtersSortOldest),
              selected: _currentFilters.sort == SearchSort.releaseDateAsc,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      sort: SearchSort.releaseDateAsc,
                    );
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSection(ThemeData theme, dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.filtersPeriod,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text(l10n.filtersPeriodAll),
                selected:
                    _currentFilters.period == SearchReleasePeriod.all &&
                    _currentFilters.exactYear == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentFilters = _currentFilters.copyWith(
                        period: SearchReleasePeriod.all,
                        exactYear: () => null,
                      );
                    });
                  }
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.filtersPeriodBefore1990),
                selected: _currentFilters.period == SearchReleasePeriod.before1990,
                onSelected: (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      period: selected
                          ? SearchReleasePeriod.before1990
                          : SearchReleasePeriod.all,
                      exactYear: () => null,
                    );
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.filtersPeriod1990s),
                selected: _currentFilters.period == SearchReleasePeriod.d1990s,
                onSelected: (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      period: selected
                          ? SearchReleasePeriod.d1990s
                          : SearchReleasePeriod.all,
                      exactYear: () => null,
                    );
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.filtersPeriod2000s),
                selected: _currentFilters.period == SearchReleasePeriod.d2000s,
                onSelected: (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      period: selected
                          ? SearchReleasePeriod.d2000s
                          : SearchReleasePeriod.all,
                      exactYear: () => null,
                    );
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.filtersPeriod2010s),
                selected: _currentFilters.period == SearchReleasePeriod.d2010s,
                onSelected: (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      period: selected
                          ? SearchReleasePeriod.d2010s
                          : SearchReleasePeriod.all,
                      exactYear: () => null,
                    );
                  });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l10n.filtersPeriod2020plus),
                selected: _currentFilters.period == SearchReleasePeriod.d2020plus,
                onSelected: (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      period: selected
                          ? SearchReleasePeriod.d2020plus
                          : SearchReleasePeriod.all,
                      exactYear: () => null,
                    );
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenresSection(ThemeData theme, dynamic l10n) {
    Map<int, String> availableGenres;
    if (_currentFilters.type == MediaType.movie) {
      availableGenres = GenreUtils.movieGenres;
    } else if (_currentFilters.type == MediaType.tv) {
      availableGenres = GenreUtils.tvGenres;
    } else {
      availableGenres = GenreUtils.getAllGenres();
    }

    final sortedEntries = availableGenres.entries.toList()
      ..sort(
        (a, b) => GenreUtils.localizedName(
          l10n,
          a.key,
        ).compareTo(GenreUtils.localizedName(l10n, b.key)),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.discoveryGenres,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: sortedEntries.map((entry) {
            final isSelected = _currentFilters.genreIds.contains(entry.key);
            return FilterChip(
              label: Text(GenreUtils.localizedName(l10n, entry.key)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  final newSet = Set<int>.from(_currentFilters.genreIds);
                  if (selected) {
                    newSet.add(entry.key);
                  } else {
                    newSet.remove(entry.key);
                  }
                  _currentFilters = _currentFilters.copyWith(genreIds: newSet);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingSection(ThemeData theme, dynamic l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.filtersRatingTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${l10n.filtersRatingSubtitle})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.filtersRatingAll),
              selected: _currentFilters.minRating == null,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFilters = _currentFilters.copyWith(
                      minRating: () => null,
                    );
                  });
                }
              },
            ),
            ChoiceChip(
              label: Text(l10n.filtersRating7Plus),
              selected: _currentFilters.minRating == 7.0,
              onSelected: (selected) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(
                    minRating: () => selected ? 7.0 : null,
                  );
                });
              },
            ),
            ChoiceChip(
              label: Text(l10n.filtersRating8Plus),
              selected: _currentFilters.minRating == 8.0,
              onSelected: (selected) {
                setState(() {
                  _currentFilters = _currentFilters.copyWith(
                    minRating: () => selected ? 8.0 : null,
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSection(ThemeData theme, dynamic l10n) {
    final isTv = _currentFilters.type == MediaType.tv;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.filtersDurationTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isTv
                  ? '(${l10n.filtersDurationNotApplicable})'
                  : '(${l10n.filtersDurationSubtitle})',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isTv
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.filtersDurationAll),
              selected: _currentFilters.duration == MovieDuration.all,
              onSelected: isTv
                  ? null
                  : (selected) {
                      if (selected) {
                        setState(() {
                          _currentFilters = _currentFilters.copyWith(
                            duration: MovieDuration.all,
                          );
                        });
                      }
                    },
            ),
            ChoiceChip(
              label: Text(l10n.filtersDurationUnder105),
              selected: _currentFilters.duration == MovieDuration.under105,
              onSelected: isTv
                  ? null
                  : (selected) {
                      setState(() {
                        _currentFilters = _currentFilters.copyWith(
                          duration: selected
                              ? MovieDuration.under105
                              : MovieDuration.all,
                        );
                      });
                    },
            ),
            ChoiceChip(
              label: Text(l10n.filtersDuration105To150),
              selected:
                  _currentFilters.duration == MovieDuration.between105And150,
              onSelected: isTv
                  ? null
                  : (selected) {
                      setState(() {
                        _currentFilters = _currentFilters.copyWith(
                          duration: selected
                              ? MovieDuration.between105And150
                              : MovieDuration.all,
                        );
                      });
                    },
            ),
            ChoiceChip(
              label: Text(l10n.filtersDurationOver150),
              selected: _currentFilters.duration == MovieDuration.over150,
              onSelected: isTv
                  ? null
                  : (selected) {
                      setState(() {
                        _currentFilters = _currentFilters.copyWith(
                          duration: selected
                              ? MovieDuration.over150
                              : MovieDuration.all,
                        );
                      });
                    },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHideSeenSection(ThemeData theme, dynamic l10n) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        l10n.filtersHideSeen,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      value: _currentFilters.hideSeen,
      onChanged: (val) {
        setState(() {
          _currentFilters = _currentFilters.copyWith(hideSeen: val);
        });
      },
    );
  }

  Widget _buildBottomBar(ThemeData theme, dynamic l10n) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentFilters = const SearchFilters();
                });
              },
              child: Text(l10n.filtersClearAll),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  widget.onApply(_currentFilters);
                  Navigator.pop(context);
                },
                child: Text(
                  widget.resultCount != null
                      ? l10n.filtersShowNResults(widget.resultCount!)
                      : l10n.filtersShowResults,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
