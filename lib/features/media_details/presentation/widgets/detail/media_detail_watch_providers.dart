import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/l10n/l10n.dart';

/// "Where to watch": logos of the subscription platforms reported by TMDB.
/// Draws nothing when there is none.
class MediaDetailWatchProviders extends StatelessWidget {
  const MediaDetailWatchProviders({super.key, required this.watchProviders});

  /// TMDB `watch/providers` results, by country code.
  final Map<String, dynamic>? watchProviders;

  @override
  Widget build(BuildContext context) {
    final results = watchProviders;
    if (results == null || results.isEmpty) return const SizedBox.shrink();

    final countryCode = results.containsKey('US') ? 'US' : results.keys.first;
    final countryData = results[countryCode] as Map<String, dynamic>;
    final List<dynamic>? flatrate = countryData['flatrate'];
    if (flatrate == null || flatrate.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.detailWatchOn,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final provider in flatrate)
              Tooltip(
                message: provider['provider_name'],
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl:
                        'https://image.tmdb.org/t/p/original${provider['logo_path']}',
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
