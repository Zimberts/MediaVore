import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mediavore/core/domain/entities/watch_providers.dart';
import 'package:mediavore/core/l10n/l10n.dart';
import 'package:mediavore/core/theme/app_palette.dart';
import 'package:mediavore/core/utils/tmdb_image_utils.dart';
import 'package:mediavore/core/widgets/section_header.dart';
import 'package:mediavore/features/settings/presentation/providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Where to watch": icons of streaming, rental and purchase platforms
/// reported by TMDB via JustWatch, for the active country.
///
/// Draws nothing when there are no offers for the selected country.
class MediaDetailWatchProviders extends StatelessWidget {
  const MediaDetailWatchProviders({
    super.key,
    required this.watchProviders,
    this.openUrl = _defaultOpenUrl,
  });

  /// TMDB `watch/providers` results, keyed by country or wrapped in `results`.
  final Map<String, dynamic>? watchProviders;

  /// Hook for opening external links (e.g. JustWatch/TMDB page); defaults to [launchUrl].
  final Future<bool> Function(Uri url) openUrl;

  static Future<bool> _defaultOpenUrl(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    if (watchProviders == null || watchProviders!.isEmpty) {
      return const SizedBox.shrink();
    }

    final parsed = WatchProviders.fromJson(watchProviders);
    final settings = context.watch<SettingsProvider>();
    final countryCode = settings.resolveWatchProvidersCountry(
      Localizations.maybeLocaleOf(context),
    );
    final countryInfo = parsed.forCountry(countryCode);

    if (countryInfo == null || countryInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    final flatrate = countryInfo.flatrate;
    final rent = countryInfo.rent;
    final buy = countryInfo.buy;
    final free = [...countryInfo.free, ...countryInfo.ads];

    if (flatrate.isEmpty && rent.isEmpty && buy.isEmpty && free.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = context.appColors;
    final link = countryInfo.link;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.detailWhereToWatch),
          const SizedBox(height: 8),
          InkWell(
            key: const Key('watch_providers_block'),
            borderRadius: BorderRadius.circular(12),
            onTap: link != null && link.isNotEmpty
                ? () {
                    final uri = Uri.tryParse(link);
                    if (uri != null) openUrl(uri);
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (flatrate.isNotEmpty)
                    _CategorySection(
                      key: const Key('watch_providers_flatrate'),
                      label: l10n.detailWatchFlatrate,
                      providers: flatrate,
                    ),
                  if (rent.isNotEmpty) ...[
                    if (flatrate.isNotEmpty) const SizedBox(height: 12),
                    _CategorySection(
                      key: const Key('watch_providers_rent'),
                      label: l10n.detailWatchRent,
                      providers: rent,
                    ),
                  ],
                  if (buy.isNotEmpty) ...[
                    if (flatrate.isNotEmpty || rent.isNotEmpty)
                      const SizedBox(height: 12),
                    _CategorySection(
                      key: const Key('watch_providers_buy'),
                      label: l10n.detailWatchBuy,
                      providers: buy,
                    ),
                  ],
                  if (free.isNotEmpty) ...[
                    if (flatrate.isNotEmpty ||
                        rent.isNotEmpty ||
                        buy.isNotEmpty)
                      const SizedBox(height: 12),
                    _CategorySection(
                      key: const Key('watch_providers_free'),
                      label: l10n.detailWatchFree,
                      providers: free,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l10n.detailWatchJustWatchAttribution,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.text2,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (link != null && link.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 12, color: colors.text2),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String label;
  final List<WatchProviderItem> providers;

  const _CategorySection({
    super.key,
    required this.label,
    required this.providers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.text2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final provider in providers)
              Tooltip(
                message: provider.providerName,
                child: Semantics(
                  label: provider.providerName,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: provider.logoPath != null
                        ? CachedNetworkImage(
                            imageUrl: TmdbImageUtils.buildUrl(
                              provider.logoPath,
                              size: TmdbImageSize.w92,
                            )!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                _FallbackIcon(name: provider.providerName),
                          )
                        : _FallbackIcon(name: provider.providerName),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  final String name;

  const _FallbackIcon({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 40,
      height: 40,
      color: colors.surface2,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
