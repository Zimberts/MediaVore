import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mediavore/core/l10n/l10n.dart';
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
