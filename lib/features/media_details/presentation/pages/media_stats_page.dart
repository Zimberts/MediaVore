import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_distribution_tab.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_overview_tab.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_scope_button.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';
import 'package:mediavore/features/search/presentation/providers/search_provider.dart';
import 'package:provider/provider.dart';

export 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';

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
                          ScopeButton(
                            label: 'All Time',
                            isSelected: _selectedScope == StatsScope.allTime,
                            onTap: () => setState(
                              () => _selectedScope = StatsScope.allTime,
                            ),
                          ),
                          ScopeButton(
                            label: _selectedScope == StatsScope.allTime
                                ? 'Year'
                                : _selectedYear!,
                            isSelected:
                                _selectedScope == StatsScope.specificYear,
                            onTap: () => _pickYear(availableYears),
                          ),
                          ScopeButton(
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
                  OverviewTab(
                    items: filteredItems,
                    metric: _selectedMetric,
                    scope: _selectedScope,
                    year: _selectedYear ?? 'All',
                    month: _selectedMonth ?? 'All',
                  ),
                  DistributionTab(
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
