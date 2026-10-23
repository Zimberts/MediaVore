import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/features/media_details/presentation/widgets/stats/stats_types.dart';

class HallOfFameItem extends StatelessWidget {
  final String label;
  final (String title, int count, int runtime)? data;
  final StatsMetric metric;

  const HallOfFameItem({
    super.key,
    required this.label,
    this.data,
    required this.metric,
  });

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
