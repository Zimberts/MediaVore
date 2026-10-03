import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';

class ActivityChart extends StatelessWidget {
  final List<SeenItem> items;
  final StatsMetric metric;
  final StatsScope scope;
  final String year;
  final String month;

  const ActivityChart({
    super.key,
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
