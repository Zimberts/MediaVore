import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

enum StatsMetric { entries, runtime }

enum StatsScope { allTime, specificYear, specificMonth }

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
    _selectedMonth = DateFormat('MMM').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();
    final allSeenItems = provider.seenItems;

    if (allSeenItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Media Stats')),
        body: const Center(child: Text('No data yet. Start watching!')),
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
          title: const Text('Media Stats'),
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                _selectedMetric == StatsMetric.entries
                    ? Icons.history
                    : Icons.timer_outlined,
              ),
              tooltip: 'Toggle Metric (Logs/Time)',
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
                            label: 'All Time',
                            isSelected: _selectedScope == StatsScope.allTime,
                            onTap: () => setState(
                              () => _selectedScope = StatsScope.allTime,
                            ),
                          ),
                          _ScopeButton(
                            label: _selectedScope == StatsScope.allTime
                                ? 'Year'
                                : _selectedYear!,
                            isSelected:
                                _selectedScope == StatsScope.specificYear,
                            onTap: () => _pickYear(availableYears),
                          ),
                          _ScopeButton(
                            label: _selectedScope != StatsScope.specificMonth
                                ? 'Month'
                                : '$_selectedMonth $_selectedYear',
                            isSelected:
                                _selectedScope == StatsScope.specificMonth,
                            onTap: () => _pickMonth(availableYears),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const TabBar(
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(
                        text: 'Overview',
                        icon: Icon(Icons.analytics_outlined, size: 20),
                      ),
                      Tab(
                        text: 'Distribution',
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
                'Select Year',
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
    const months = [
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
                      'Select Period',
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
                                      child: Text(m),
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

      final monthMatch = DateFormat('MMM').format(i.seenDate) == _selectedMonth;
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
          title: 'Total Watch Time',
          child: Column(
            children: [
              Text(
                '${days}d ${remainingHours}h ${minutes}m',
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
                    label: 'Movies',
                    value: '$movieCount',
                    icon: Icons.movie,
                  ),
                  const SizedBox(width: 16),
                  _SummaryMiniCard(
                    label: 'Episodes',
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
          title: 'Hall of Fame (${metric.name})',
          child: Column(
            children: [
              _HallOfFameItem(
                label: 'Most Watched Movie',
                data: topMovie,
                metric: metric,
              ),
              const Divider(),
              _HallOfFameItem(
                label: 'Most Watched Series',
                data: topTV,
                metric: metric,
              ),
              const Divider(),
              _HallOfFameItem(
                label: 'Most Watched Episode',
                data: topEp,
                metric: metric,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StatCard(
          title: metric == StatsMetric.entries
              ? 'Viewing Activity (logs)'
              : 'Viewing Activity (minutes)',
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
        ? '${data!.$2} logs'
        : '${(data!.$3 / 60).toStringAsFixed(1)}h';

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
    final activityData = <String, double>{};
    String dateFormat;

    if (scope == StatsScope.allTime) {
      final years = items.map((i) => i.seenDate.year).toSet();
      if (years.length > 5) {
        dateFormat = 'yyyy';
      } else {
        dateFormat = 'MMM yy';
      }
    } else if (scope == StatsScope.specificYear) {
      dateFormat = 'MMM';
    } else {
      dateFormat = 'dd';
    }

    for (final item in items) {
      final key = DateFormat(dateFormat).format(item.seenDate);
      final value = metric == StatsMetric.entries
          ? 1.0
          : (item.runtime?.toDouble() ?? 0.0);
      activityData[key] = (activityData[key] ?? 0) + value;
    }

    final sortedKeys = activityData.keys.toList();
    _sortKeys(sortedKeys, dateFormat);

    if (sortedKeys.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No activity data')),
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
                  toY: activityData[e.value]!,
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
                  '${sortedKeys[groupIndex]}\n${rod.toY.toInt()} ${metric == StatsMetric.entries ? 'logs' : 'min'}',
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

  void _sortKeys(List<String> keys, String dateFormat) {
    try {
      if (dateFormat == 'dd') {
        keys.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      } else if (dateFormat == 'MMM') {
        const months = [
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
        keys.sort((a, b) => months.indexOf(a).compareTo(months.indexOf(b)));
      } else {
        keys.sort(
          (a, b) => DateFormat(
            dateFormat,
          ).parse(a).compareTo(DateFormat(dateFormat).parse(b)),
        );
      }
    } catch (_) {
      keys.sort();
    }
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
        for (final genre in item.genres!) {
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
          title: 'Media Split (${metric.name})',
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
                    title: '${e.key.name}\n$percentage%',
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
          title: 'Top Genres (by ${metric.name})',
          child: Column(
            children: topGenres.map((e) {
              final percentage = totalValue > 0
                  ? (e.value / totalValue * 100).toStringAsFixed(1)
                  : '0';
              final displayValue = metric == StatsMetric.entries
                  ? e.value.toInt().toString()
                  : '${(e.value / 60).toStringAsFixed(1)}h';
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
                          '$displayValue ($percentage%)',
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
