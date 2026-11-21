import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/media_details/domain/services/stats_calculator.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_activity_chart.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_card.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_decade_section.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_hall_of_fame_item.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_lists_section.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_media_split_bar.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_scope_button.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_series_progression_section.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_summary_mini_card.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_top_genres_list.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

export 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';

/// Abbreviated month name in the active locale for a [statsMonthKeys] entry.
String _monthLabel(String key) {
  final idx = statsMonthKeys.indexOf(key);
  if (idx < 0) return key;
  return DateFormat.MMM().format(DateTime(2000, idx + 1));
}

class MediaStatsPage extends StatefulWidget {
  const MediaStatsPage({super.key});

  @override
  State<MediaStatsPage> createState() => _MediaStatsPageState();
}

class _MediaStatsPageState extends State<MediaStatsPage> {
  StatsMetric _selectedMetric = StatsMetric.entries;
  StatsScope _selectedScope = StatsScope.allTime;
  String? _selectedYear;
  String? _selectedMonth;

  Map<int, MediaItem> _cachedSeenItems = const {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year.toString();
    _selectedMonth = statsMonthKey(now);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCachedSeenItems();
    });
  }

  Future<void> _loadCachedSeenItems() async {
    if (!mounted) return;
    final provider = context.read<SearchProvider>();
    final cached = await provider.getCachedSeenMediaItems();
    if (mounted) {
      setState(() {
        _cachedSeenItems = cached;
      });
    }
  }

  void _previousPeriod() {
    setState(() {
      if (_selectedScope == StatsScope.specificYear) {
        final year = int.tryParse(_selectedYear ?? '') ?? DateTime.now().year;
        _selectedYear = (year - 1).toString();
      } else if (_selectedScope == StatsScope.specificMonth) {
        final idx = statsMonthKeys.indexOf(_selectedMonth ?? 'Jan');
        if (idx > 0) {
          _selectedMonth = statsMonthKeys[idx - 1];
        } else {
          _selectedMonth = statsMonthKeys.last;
          final year = int.tryParse(_selectedYear ?? '') ?? DateTime.now().year;
          _selectedYear = (year - 1).toString();
        }
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_selectedScope == StatsScope.specificYear) {
        final year = int.tryParse(_selectedYear ?? '') ?? DateTime.now().year;
        _selectedYear = (year + 1).toString();
      } else if (_selectedScope == StatsScope.specificMonth) {
        final idx = statsMonthKeys.indexOf(_selectedMonth ?? 'Jan');
        if (idx < statsMonthKeys.length - 1) {
          _selectedMonth = statsMonthKeys[idx + 1];
        } else {
          _selectedMonth = statsMonthKeys.first;
          final year = int.tryParse(_selectedYear ?? '') ?? DateTime.now().year;
          _selectedYear = (year + 1).toString();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final allSeenItems = provider.seenItems;

    if (allSeenItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.statsTitle)),
        body: Center(child: Text(context.l10n.statsEmpty)),
      );
    }

    final availableYears = StatsCalculator.getAvailableYears(allSeenItems);
    if (_selectedYear == null || !availableYears.contains(_selectedYear)) {
      if (availableYears.isNotEmpty && _selectedScope != StatsScope.allTime) {
        _selectedYear ??= availableYears.first;
      }
    }

    final filteredItems = StatsCalculator.filterItems(
      allSeenItems,
      scope: _selectedScope,
      year: _selectedYear,
      month: _selectedMonth,
    );

    final watchTime = StatsCalculator.calculateWatchTime(filteredItems);
    final split = StatsCalculator.calculateMediaSplit(filteredItems);
    final hallOfFame = StatsCalculator.calculateHallOfFame(
      filteredItems,
      metric: _selectedMetric,
    );
    final topGenres = StatsCalculator.calculateTopGenres(
      filteredItems,
      metric: _selectedMetric,
      genreIdLocalizer: (id) => GenreUtils.localizedName(context.l10n, id),
    );

    // All-time sections
    final decades = StatsCalculator.calculateDecadeStats(
      allSeenItems,
      _cachedSeenItems,
      before1990Label: context.l10n.statsDecadeBefore1990,
      after2020Label: context.l10n.statsDecadeAfter2020,
    );
    final seriesProgression = StatsCalculator.calculateSeriesProgression(
      allSeenItems,
      _cachedSeenItems,
    );

    final watchlistCount = provider.getListItemCount('watchlist');
    final customListNames = provider.listNames
        .where((n) => n != 'watchlist')
        .toList();
    final customListsCount = customListNames.length;
    final customListsItemsCount = customListNames.fold<int>(
      0,
      (sum, name) => sum + provider.getListItemCount(name),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.statsTitle),
        actions: [
          IconButton(
            key: const Key('stats_toggle_metric'),
            icon: Icon(
              _selectedMetric == StatsMetric.entries
                  ? Icons.history
                  : Icons.timer_outlined,
            ),
            tooltip: context.l10n.statsToggleMetric,
            onPressed: () {
              setState(() {
                _selectedMetric = _selectedMetric == StatsMetric.entries
                    ? StatsMetric.runtime
                    : StatsMetric.entries;
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Period Scope Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ScopeButton(
                  label: context.l10n.statsAllTime,
                  isSelected: _selectedScope == StatsScope.allTime,
                  onTap: () =>
                      setState(() => _selectedScope = StatsScope.allTime),
                ),
                ScopeButton(
                  label: context.l10n.statsYear,
                  isSelected: _selectedScope == StatsScope.specificYear,
                  onTap: () =>
                      setState(() => _selectedScope = StatsScope.specificYear),
                ),
                ScopeButton(
                  label: context.l10n.statsMonth,
                  isSelected: _selectedScope == StatsScope.specificMonth,
                  onTap: () =>
                      setState(() => _selectedScope = StatsScope.specificMonth),
                ),
              ],
            ),
          ),

          // Period navigation (< label >) when Year or Month is selected
          if (_selectedScope != StatsScope.allTime) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: context.l10n.statsPreviousPeriod,
                  onPressed: _previousPeriod,
                ),
                TextButton(
                  onPressed: () {
                    if (_selectedScope == StatsScope.specificYear) {
                      _pickYear(availableYears);
                    } else {
                      _pickMonth(availableYears);
                    }
                  },
                  child: Text(
                    _selectedScope == StatsScope.specificYear
                        ? _selectedYear!
                        : '${_monthLabel(_selectedMonth!)} $_selectedYear',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: context.l10n.statsNextPeriod,
                  onPressed: _nextPeriod,
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Period data or dedicated empty message
          if (filteredItems.isEmpty) ...[
            Card(
              key: const Key('stats_no_data'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.statsNoDataForPeriod,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Total watch time
            StatCard(
              title: context.l10n.statsTotalWatchTime,
              child: Column(
                children: [
                  Text(
                    context.l10n.statsDuration(
                      watchTime.days,
                      watchTime.remainingHours,
                      watchTime.minutes,
                    ),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SummaryMiniCard(
                        label: context.l10n.statsMoviesCount(split.movieCount),
                        value: split.movieCount.toString(),
                        icon: Icons.movie_outlined,
                      ),
                      SummaryMiniCard(
                        label: context.l10n.statsEpisodesCount(split.tvCount),
                        value: split.tvCount.toString(),
                        icon: Icons.tv_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Viewing Activity Chart
            StatCard(
              title: _selectedMetric == StatsMetric.entries
                  ? context.l10n.statsActivityLogs
                  : context.l10n.statsActivityMinutes,
              child: ActivityChart(
                items: filteredItems,
                metric: _selectedMetric,
                scope: _selectedScope,
                year: _selectedYear ?? DateTime.now().year.toString(),
                month: _selectedMonth ?? statsMonthKey(DateTime.now()),
              ),
            ),

            const SizedBox(height: 12),

            // Hall of Fame
            StatCard(
              title: context.l10n.statsHallOfFame(
                statsMetricLabel(context, _selectedMetric),
              ),
              child: Column(
                children: [
                  HallOfFameItem(
                    label: context.l10n.statsMostWatchedMovie,
                    entry: hallOfFame.topMovie,
                    metric: _selectedMetric,
                  ),
                  const Divider(height: 16),
                  HallOfFameItem(
                    label: context.l10n.statsMostWatchedSeries,
                    entry: hallOfFame.topTV,
                    metric: _selectedMetric,
                  ),
                  const Divider(height: 16),
                  HallOfFameItem(
                    label: context.l10n.statsMostWatchedEpisode,
                    entry: hallOfFame.topEpisode,
                    metric: _selectedMetric,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Media Split (horizontal stacked bar)
            StatCard(
              title: context.l10n.statsMediaSplit(
                statsMetricLabel(context, _selectedMetric),
              ),
              child: MediaSplitBar(split: split, metric: _selectedMetric),
            ),

            const SizedBox(height: 12),

            // Top genres
            if (topGenres.isNotEmpty) ...[
              StatCard(
                title: context.l10n.statsTopGenres(
                  statsMetricLabel(context, _selectedMetric),
                ),
                child: TopGenresList(
                  genres: topGenres,
                  metric: _selectedMetric,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],

          // All-time sections (independent of period)
          if (decades.isNotEmpty) ...[
            const SizedBox(height: 8),
            StatCard(
              title: context.l10n.statsDecades,
              child: DecadeSection(decades: decades),
            ),
          ],

          if (seriesProgression.isNotEmpty) ...[
            const SizedBox(height: 12),
            StatCard(
              title: context.l10n.statsSeriesProgression,
              child: SeriesProgressionSection(series: seriesProgression),
            ),
          ],

          const SizedBox(height: 12),

          // Lists and discovery
          StatCard(
            title: context.l10n.statsListsAndDiscovery,
            child: ListsAndDiscoverySection(
              watchlistCount: watchlistCount,
              customListsCount: customListsCount,
              customListsItemsCount: customListsItemsCount,
            ),
          ),

          // Footer disclaimer
          const SizedBox(height: 20),
          Center(
            child: Text(
              context.l10n.statsFooterDatedHistory,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _pickYear(List<String> availableYears) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                context.l10n.statsSelectYear,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: availableYears
                    .map(
                      (y) => ListTile(
                        title: Text(y, textAlign: TextAlign.center),
                        selected:
                            _selectedYear == y &&
                            _selectedScope == StatsScope.specificYear,
                        onTap: () {
                          setState(() {
                            _selectedYear = y;
                            _selectedScope = StatsScope.specificYear;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickMonth(List<String> availableYears) {
    final sortedYears = List<String>.from(availableYears)
      ..sort((a, b) => a.compareTo(b));
    final initialPage = sortedYears.indexOf(_selectedYear ?? '');
    final pageController = PageController(
      initialPage: initialPage >= 0 ? initialPage : 0,
    );

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: context.l10n.statsPreviousPeriod,
                      onPressed: () {
                        pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                    Text(
                      context.l10n.statsSelectPeriod,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: context.l10n.statsNextPeriod,
                      onPressed: () {
                        pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: pageController,
                  itemCount: sortedYears.length,
                  onPageChanged: (index) {
                    setModalState(() {
                      _selectedYear = sortedYears[index];
                    });
                    setState(() {
                      _selectedYear = sortedYears[index];
                    });
                  },
                  itemBuilder: (context, yearIndex) {
                    final year = sortedYears[yearIndex];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            year,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Expanded(
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            childAspectRatio: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            children: statsMonthKeys
                                .map(
                                  (m) => InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedMonth = m;
                                        _selectedYear = year;
                                        _selectedScope =
                                            StatsScope.specificMonth;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color:
                                            _selectedMonth == m &&
                                                _selectedYear == year &&
                                                _selectedScope ==
                                                    StatsScope.specificMonth
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer
                                            : null,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).dividerColor.withValues(alpha: 0.1),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(_monthLabel(m)),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
