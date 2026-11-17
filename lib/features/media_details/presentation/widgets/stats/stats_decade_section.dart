import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/features/media_details/domain/services/stats_calculator.dart';

class DecadeSection extends StatelessWidget {
  final List<DecadeStatItem> decades;

  const DecadeSection({super.key, required this.decades});

  @override
  Widget build(BuildContext context) {
    if (decades.isEmpty) return const SizedBox.shrink();

    final maxCount = decades.map((d) => d.count).fold<int>(1, max);

    return Column(
      children: decades.map((item) {
        final ratio = (item.count / maxCount).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.decadeLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.count}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.averageRating != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            context.l10n.statsAverageRating(
                              item.averageRating!.toStringAsFixed(1),
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
