import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/media_item.dart';
import 'package:mediavore/core/domain/entities/seen_item.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_activity_chart.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_card.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_hall_of_fame_item.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_summary_mini_card.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';

class OverviewTab extends StatelessWidget {
  final List<SeenItem> items;
  final StatsMetric metric;
  final StatsScope scope;
  final String year;
  final String month;

  const OverviewTab({
    super.key,
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
        StatCard(
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
                  SummaryMiniCard(
                    label: 'Movies',
                    value: '$movieCount',
                    icon: Icons.movie,
                  ),
                  const SizedBox(width: 16),
                  SummaryMiniCard(
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
        StatCard(
          title: 'Hall of Fame (${metric.name})',
          child: Column(
            children: [
              HallOfFameItem(
                label: 'Most Watched Movie',
                data: topMovie,
                metric: metric,
              ),
              const Divider(),
              HallOfFameItem(
                label: 'Most Watched Series',
                data: topTV,
                metric: metric,
              ),
              const Divider(),
              HallOfFameItem(
                label: 'Most Watched Episode',
                data: topEp,
                metric: metric,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatCard(
          title: metric == StatsMetric.entries
              ? 'Viewing Activity (logs)'
              : 'Viewing Activity (minutes)',
          child: ActivityChart(
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
