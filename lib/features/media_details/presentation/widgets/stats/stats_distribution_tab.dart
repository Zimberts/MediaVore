import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_card.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';

class DistributionTab extends StatelessWidget {
  final List<SeenItem> items;
  final StatsMetric metric;
  const DistributionTab({super.key, required this.items, required this.metric});

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
        StatCard(
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
        StatCard(
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
