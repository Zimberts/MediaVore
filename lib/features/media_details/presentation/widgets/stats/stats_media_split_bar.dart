import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/features/media_details/domain/services/stats_calculator.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';

class MediaSplitBar extends StatelessWidget {
  final MediaSplitResult split;
  final StatsMetric metric;

  const MediaSplitBar({
    super.key,
    required this.split,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final moviePct = split.moviePercentage(metric);
    final tvPct = split.tvPercentage(metric);

    final colors = context.appColors;
    final movieColor = colors.movie;
    final tvColor = colors.series;

    Widget bar;
    if (moviePct <= 0 && tvPct <= 0) {
      bar = Container(
        height: 12,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    } else if (moviePct > 0 && tvPct <= 0) {
      bar = Container(
        height: 12,
        decoration: BoxDecoration(
          color: movieColor,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    } else if (tvPct > 0 && moviePct <= 0) {
      bar = Container(
        height: 12,
        decoration: BoxDecoration(
          color: tvColor,
          borderRadius: BorderRadius.circular(6),
        ),
      );
    } else {
      final movieFlex = (moviePct * 10).round().clamp(1, 999);
      final tvFlex = (tvPct * 10).round().clamp(1, 999);
      bar = ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Row(
          children: [
            Expanded(
              flex: movieFlex,
              child: Container(height: 12, color: movieColor),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: tvFlex,
              child: Container(height: 12, color: tvColor),
            ),
          ],
        ),
      );
    }

    final movieValueStr = metric == StatsMetric.entries
        ? context.l10n.statsMoviesCount(split.movieCount)
        : context.l10n.statsHours((split.movieRuntime / 60).toStringAsFixed(1));

    final tvValueStr = metric == StatsMetric.entries
        ? context.l10n.statsEpisodesCount(split.tvCount)
        : context.l10n.statsHours((split.tvRuntime / 60).toStringAsFixed(1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar,
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _LegendItem(
              color: movieColor,
              icon: Icons.movie_outlined,
              label: '$movieValueStr (${moviePct.toStringAsFixed(1)}%)',
            ),
            _LegendItem(
              color: tvColor,
              icon: Icons.tv_outlined,
              label: '$tvValueStr (${tvPct.toStringAsFixed(1)}%)',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
