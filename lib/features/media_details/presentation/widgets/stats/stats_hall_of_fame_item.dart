import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/features/media_details/domain/services/stats_calculator.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';

class HallOfFameItem extends StatelessWidget {
  final String label;
  final HallOfFameEntry? entry;
  final (String title, int count, int runtime)? data;
  final StatsMetric metric;

  const HallOfFameItem({
    super.key,
    required this.label,
    this.entry,
    this.data,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final title = entry?.title ?? data?.$1;
    final count = entry?.count ?? data?.$2;
    final runtime = entry?.runtime ?? data?.$3;

    if (title == null || count == null || runtime == null) {
      return const SizedBox.shrink();
    }

    final valueDisplay = metric == StatsMetric.entries
        ? context.l10n.statsLogCount(count)
        : context.l10n.statsHours((runtime / 60).toStringAsFixed(1));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
