import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/core/utils/genres.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

enum StatsMetric { entries, runtime }

enum StatsScope { allTime, specificYear, specificMonth }

/// Locale-independent month keys used for the selected period.
const _monthKeys = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _monthKey(DateTime date) => _monthKeys[date.month - 1];

/// Abbreviated month name in the active locale for a [_monthKeys] entry.
String _monthLabel(String key) =>
    DateFormat.MMM().format(DateTime(2000, _monthKeys.indexOf(key) + 1));

String _metricLabel(BuildContext context, StatsMetric metric) =>
    metric == StatsMetric.entries
    ? context.l10n.statsMetricLogs
    : context.l10n.statsMetricTime;

String _mediaTypeLabel(BuildContext context, MediaType type) =>
    type == MediaType.movie
    ? context.l10n.commonMovies
    : context.l10n.commonTvShows;

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

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year.toString();
    _selectedMonth = _monthKey(DateTime.now());
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

    final availableYears = _getAvailableYears(allSeenItems);
    if (_selectedYear == null || !availableYears.contains(_selectedYear)) {
      _selectedYear = availableYears.isNotEmpty
          ? availableYears.first
          : DateTime.now().year.toString();
    }

    final filteredItems = _filterItems(allSeenItems);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.statsTitle),
          elevation: 0,
          actions: [
            IconButton(
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
        body: Column(
          children: [
            Material(
              color:
                  Theme.of(context).appBarTheme.backgroundColor ??
                  Theme.of(context).primaryColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _ScopeButton(
                            label: context.l10n.statsAllTime,
                            isSelected: _selectedScope == StatsScope.allTime,
                            onTap: () => setState(
                              () => _selectedScope = StatsScope.allTime,
                            ),
                          ),
                          _ScopeButton(
                            label: _selectedScope == StatsScope.allTime
                                ? context.l10n.statsYear
                                : _selectedYear!,
                            isSelected:
                                _selectedScope == StatsScope.specificYear,
                            onTap: () => _pickYear(availableYears),
                          ),
                          _ScopeButton(
                            label: _selectedScope != StatsScope.specificMonth
                                ? context.l10n.statsMonth
                                : '${_monthLabel(_selectedMonth!)} $_selectedYear',
                            isSelected:
                                _selectedScope == StatsScope.specificMonth,
                            onTap: () => _pickMonth(availableYears),
                          ),
                        ],
                      ),
                    ),
                  ),
                  TabBar(
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(
                        text: context.l10n.statsOverview,
                        icon: Icon(Icons.analytics_outlined, size: 20),
                      ),
                      Tab(
                        text: context.l10n.statsDistribution,
                        icon: Icon(Icons.pie_chart_outline, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(
                    items: filteredItems,
                    metric: _selectedMetric,
                    scope: _selectedScope,
                    year: _selectedYear ?? 'All',
                    month: _selectedMonth ?? 'All',
                  ),
                  _DistributionTab(
                    items: filteredItems,
                    metric: _selectedMetric,
                  ),
                ],
              ),
            ),
          ],
        ),
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
    const months = _monthKeys;

    // Sort available years to ensure consistent swiping (newest to oldest or oldest to newest)
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
                            children: months
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

  List<String> _getAvailableYears(List<SeenItem> items) {
    final years = items.map((i) => i.seenDate.year.toString()).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<SeenItem> _filterItems(List<SeenItem> items) {
    return items.where((i) {
      if (_selectedScope == StatsScope.allTime) return true;

      final yearMatch = i.seenDate.year.toString() == _selectedYear;
      if (_selectedScope == StatsScope.specificYear) return yearMatch;

      final monthMatch = _monthKey(i.seenDate) == _selectedMonth;
      return yearMatch && monthMatch;
    }).toList();
  }
}

class _ScopeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScopeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final List<SeenItem> items;
  final StatsMetric metric;
  final StatsScope scope;
  final String year;
  final String month;

  const _OverviewTab({
    required this.items,
    required this.metric,
    required this.scope,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final totalRuntime = items.fold<int>(
      0,
      (sum, item) => sum + (item.runtime ?? 0),
    );
    final hours = totalRuntime ~/ 60;
    final minutes = totalRuntime % 60;
    final days = hours ~/ 24;
    final remainingHours = hours % 24;

    final movieCount = items.where((i) => i.type == MediaType.movie).length;
    final tvCount = items.where((i) => i.type == MediaType.tv).length;

    // Most seen calculations
    final Map<int, (String title, int count, int runtime)> movieCounts = {};
    final Map<int, (String title, int count, int runtime)> tvCounts = {};
    final Map<String, (String title, int count, int runtime)> episodeCounts =
        {};

    for (final item in items) {
      if (item.type == MediaType.movie) {
        final existing = movieCounts[item.tmdbId] ?? (item.title, 0, 0);
        movieCounts[item.tmdbId] = (
          existing.$1,
          existing.$2 + 1,
          existing.$3 + (item.runtime ?? 0),
        );
      } else {
        final existing = tvCounts[item.tmdbId] ?? (item.title, 0, 0);
        tvCounts[item.tmdbId] = (
          existing.$1,
          existing.$2 + 1,
          existing.$3 + (item.runtime ?? 0),
        );

        if (item.seasonNumber != null && item.episodeNumber != null) {
          final epKey =
              '${item.tmdbId}_${item.seasonNumber}_${item.episodeNumber}';
          final epTitle =
              '${item.title} S${item.seasonNumber}E${item.episodeNumber}';
          final existingEp = episodeCounts[epKey] ?? (epTitle, 0, 0);
          episodeCounts[epKey] = (
            existingEp.$1,
            existingEp.$2 + 1,
            existingEp.$3 + (item.runtime ?? 0),
          );
        }
      }
    }

    final topMovie = _getTop(movieCounts, metric);
    final topTV = _getTop(tvCounts, metric);
    final topEp = _getTopEp(episodeCounts, metric);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(
          title: context.l10n.statsTotalWatchTime,
          child: Column(
            children: [
              Text(
                context.l10n.statsDuration(days, remainingHours, minutes),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SummaryMiniCard(
                    label: context.l10n.commonMovies,
                    value: '$movieCount',
                    icon: Icons.movie,
                  ),
                  const SizedBox(width: 16),
                  _SummaryMiniCard(
                    label: context.l10n.statsEpisodes,
                    value: '$tvCount',
                    icon: Icons.tv,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: context.l10n.statsHallOfFame(_metricLabel(context, metric)),
          child: Column(
            children: [
              _HallOfFameItem(
                label: context.l10n.statsMostWatchedMovie,
                data: topMovie,
                metric: metric,
              ),
              const Divider(),
              _HallOfFameItem(
                label: context.l10n.statsMostWatchedSeries,
                data: topTV,
                metric: metric,
              ),
              const Divider(),
              _HallOfFameItem(
                label: context.l10n.statsMostWatchedEpisode,
                data: topEp,
                metric: metric,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: metric == StatsMetric.entries
              ? context.l10n.statsActivityLogs
              : context.l10n.statsActivityMinutes,
          child: _ActivityChart(
            items: items,
            metric: metric,
            scope: scope,
            year: year,
            month: month,
          ),
        ),
      ],
    );
  }

  (String, int, int)? _getTop(
    Map<int, (String, int, int)> counts,
    StatsMetric metric,
  ) {
    if (counts.isEmpty) return null;
    final entries = counts.values.toList();
    if (metric == StatsMetric.entries) {
      entries.sort((a, b) => b.$2.compareTo(a.$2));
    } else {
      entries.sort((a, b) => b.$3.compareTo(a.$3));
    }
    return entries.first;
  }

  (String, int, int)? _getTopEp(
    Map<String, (String, int, int)> counts,
    StatsMetric metric,
  ) {
    if (counts.isEmpty) return null;
    final entries = counts.values.toList();
    if (metric == StatsMetric.entries) {
      entries.sort((a, b) => b.$2.compareTo(a.$2));
    } else {
      entries.sort((a, b) => b.$3.compareTo(a.$3));
    }
    return entries.first;
  }
}

class _HallOfFameItem extends StatelessWidget {
  final String label;
  final (String title, int count, int runtime)? data;
  final StatsMetric metric;

  const _HallOfFameItem({required this.label, this.data, required this.metric});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox();

    final valueDisplay = metric == StatsMetric.entries
        ? context.l10n.statsLogCount(data!.$2)
        : context.l10n.statsHours((data!.$3 / 60).toStringAsFixed(1));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data!.$1,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                valueDisplay,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  final List<SeenItem> items;
  final StatsMetric metric;
  final StatsScope scope;
  final String year;
  final String month;

  const _ActivityChart({
    required this.items,
    required this.metric,
    required this.scope,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final activityData = <DateTime, double>{};
    String dateFormat;
    DateTime Function(DateTime) bucket;

    if (scope == StatsScope.allTime) {
      final years = items.map((i) => i.seenDate.year).toSet();
      if (years.length > 5) {
        dateFormat = 'yyyy';
        bucket = (d) => DateTime(d.year);
      } else {
        dateFormat = 'MMM yy';
        bucket = (d) => DateTime(d.year, d.month);
      }
    } else if (scope == StatsScope.specificYear) {
      dateFormat = 'MMM';
      bucket = (d) => DateTime(d.year, d.month);
    } else {
      dateFormat = 'dd';
      bucket = (d) => DateTime(d.year, d.month, d.day);
    }

    for (final item in items) {
      final key = bucket(item.seenDate);
      final value = metric == StatsMetric.entries
          ? 1.0
          : (item.runtime?.toDouble() ?? 0.0);
      activityData[key] = (activityData[key] ?? 0) + value;
    }

    final sortedBuckets = activityData.keys.toList()..sort();
    final formatter = DateFormat(dateFormat);
    final sortedKeys = sortedBuckets.map(formatter.format).toList();

    if (sortedKeys.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(context.l10n.statsNoActivity)),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: sortedKeys.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: activityData[sortedBuckets[e.key]]!,
                  color: Theme.of(context).colorScheme.primary,
                  width: sortedKeys.length > 15 ? 6 : 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedKeys.length) {
                    return const SizedBox();
                  }

                  int skip = 1;
                  if (sortedKeys.length > 20) {
                    skip = 5;
                  } else if (sortedKeys.length > 10) {
                    skip = 2;
                  }

                  if (index % skip != 0 && index != sortedKeys.length - 1) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      sortedKeys[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  context.l10n.statsTooltip(
                    sortedKeys[groupIndex],
                    rod.toY.toInt(),
                    metric == StatsMetric.entries
                        ? context.l10n.statsMetricLogs
                        : 'min',
                  ),
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DistributionTab extends StatelessWidget {
  final List<SeenItem> items;
  final StatsMetric metric;
  const _DistributionTab({required this.items, required this.metric});

  @override
  Widget build(BuildContext context) {
    final genreData = <String, double>{};
    final typeData = <MediaType, double>{};
    double totalValue = 0;

    for (final item in items) {
      final value = metric == StatsMetric.entries
          ? 1.0
          : (item.runtime?.toDouble() ?? 0.0);
      totalValue += value;

      typeData[item.type] = (typeData[item.type] ?? 0) + value;
      if (item.genres != null) {
        for (final rawGenre in item.genres!) {
          // History may mix languages; group by TMDB id when known.
          final genreId = GenreUtils.getGenreIdByName(rawGenre);
          final genre = genreId != null
              ? GenreUtils.localizedName(context.l10n, genreId)
              : rawGenre;
          genreData[genre] = (genreData[genre] ?? 0) + value;
        }
      }
    }

    final sortedGenres = genreData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGenres = sortedGenres.take(8).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCard(
          title: context.l10n.statsMediaSplit(_metricLabel(context, metric)),
          child: SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: typeData.entries.map((e) {
                  final color = e.key == MediaType.movie
                      ? Colors.blue
                      : Colors.orange;
                  final percentage = totalValue > 0
                      ? (e.value / totalValue * 100).toStringAsFixed(1)
                      : '0';
                  return PieChartSectionData(
                    color: color,
                    value: e.value,
                    title: context.l10n.statsPieLabel(
                      _mediaTypeLabel(context, e.key),
                      percentage,
                    ),
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: context.l10n.statsTopGenres(_metricLabel(context, metric)),
          child: Column(
            children: topGenres.map((e) {
              final percentage = totalValue > 0
                  ? (e.value / totalValue * 100).toStringAsFixed(1)
                  : '0';
              final displayValue = metric == StatsMetric.entries
                  ? e.value.toInt().toString()
                  : context.l10n.statsHours((e.value / 60).toStringAsFixed(1));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key),
                        Text(
                          context.l10n.statsGenreValue(
                            displayValue,
                            percentage,
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: sortedGenres.isNotEmpty
                          ? e.value / sortedGenres.first.value
                          : 0,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SummaryMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMiniCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _StatCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
